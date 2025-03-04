import 'dart:convert';

import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/exportCSV.dart';
import 'package:budget/widgets/globalSnackBar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/progressBar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/viewAllTransactionsButton.dart';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:budget/struct/randomConstants.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:http/http.dart' as http;

class ImportCSV extends StatefulWidget {
  const ImportCSV({Key? key}) : super(key: key);

  @override
  State<ImportCSV> createState() => _ImportCSVState();
}

class _ImportCSVState extends State<ImportCSV> {
  _getHeaderIndex(List<String> headers, String header) {
    int index = 0;
    for (String headerEntry in headers) {
      if (header == headerEntry) {
        return index;
      }
      index++;
    }
    return -1;
  }

  Future<String?> _getCSVStringFromBackupFile() async {
    dynamic csvStringOut = await openLoadingPopupTryCatch(() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (result != null) {
        String csvString;
        if (kIsWeb) {
          List<int> fileBytes = result.files.single.bytes!;
          csvString = utf8.decode(fileBytes);
        } else {
          File file = File(result.files.single.path ?? "");
          Uint8List fileBytes = await file.readAsBytes();
          DecodingResult decoded = await CharsetDetector.autoDecode(fileBytes);
          csvString = decoded.string;
        }
        return csvString;
      } else {
        throw "no-file-selected".tr();
      }
    }, onError: (e) {
      openPopup(
        context,
        title: "csv-error".tr(),
        description: e.toString(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.error_outlined
            : Icons.error_rounded,
        onSubmitLabel: "ok".tr(),
        onSubmit: () {
          Navigator.of(context).pop();
        },
        barrierDismissible: false,
      );
    });
    if (csvStringOut is String) {
      return csvStringOut;
    }
    return null;
  }

  Future<void> _assignColumns(String csvString,
      {bool importFromSheets = false}) async {
    try {
      List<List<String>> fileContents = CsvToListConverter().convert(
        csvString,
        eol: '\n',
        shouldParseNumbers: false,
      );
      int maxColumns = fileContents.fold(
          0, (prev, element) => element.length > prev ? element.length : prev);

      // Add missing values to rows with fewer columns
      fileContents = fileContents
          .map((row) => row + List.filled(maxColumns - row.length, ""))
          .toList();

      List<String> headers = fileContents[0];
      List<String> firstEntry = fileContents[1];

      String dateFormat = "";
      Map<String, Map<String, dynamic>> assignedColumns = {
        "date": {
          "displayName": "date",
          "headerValues": [
            "FormattedDate", //For the Google Sheet template
            "date",
            "date created",
            "dateCreated"
          ],
          "required": true,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
        },
        "amount": {
          "displayName": "amount",
          "headerValues": ["amount"],
          "required": true,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
        },
        "category": {
          "displayName": "category",
          "headerValues": ["category", "category name", "categoryName"],
          // "extraOptions": ["Use Smart Categories"],
          //This will be implemented later... in the future
          //Use title to determine category. If smart category entry not found, ask user to select which category when importing. Save these selections to that category.
          "required": true,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
        },
        "name": {
          "displayName": "title",
          "headerValues": ["title", "name"],
          "required": false,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
        },
        "note": {
          "displayName": "note",
          "headerValues": ["note"],
          "required": false,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
        },
        "wallet": {
          "displayName": "account",
          "headerValues": ["wallet", "account"],
          "required": true,
          "setHeaderValue": "",
          "setHeaderIndex": -1,
          "canSelectCurrentWallet": true,
        },
      };
      for (dynamic key in assignedColumns.keys) {
        String setHeaderValue = determineInitialValue(
            assignedColumns[key]!["headerValues"],
            headers,
            assignedColumns[key]!["required"],
            assignedColumns[key]!["canSelectCurrentWallet"]);
        assignedColumns[key]!["setHeaderValue"] = setHeaderValue;
        assignedColumns[key]!["setHeaderIndex"] =
            _getHeaderIndex(headers, setHeaderValue);
      }

      // Skip assigning columns, if they used the template this will succeed
      if (importFromSheets) {
        try {
          await _importEntries(assignedColumns, dateFormat, fileContents,
              noPop: true);
          return;
        } catch (e) {
          openPopup(
            context,
            icon: appStateSettings["outlinedIcons"]
                ? Icons.warning_outlined
                : Icons.warning_rounded,
            title: "csv-error".tr(),
            description: "consider-csv-template".tr() + e.toString(),
            onSubmit: () {
              Navigator.pop(context);
            },
            onSubmitLabel: "ok".tr(),
            onCancel: () {
              importFromSheets
                  ? getGoogleSheetTemplate(context)
                  : saveSampleCSV();
            },
            onCancelLabel: "get-template".tr(),
          );
        }
      }

      openBottomSheet(
        context,
        PopupFramework(
          title: "assign-columns".tr(),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Table(
                      defaultColumnWidth: IntrinsicColumnWidth(),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: <TableRow>[
                        TableRow(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          children: <Widget>[
                            for (dynamic header in headers)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11.0, vertical: 5),
                                child: TextFont(
                                  text: header.toString(),
                                  fontWeight: FontWeight.bold,
                                  textColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontSize: 16,
                                ),
                              )
                          ],
                        ),
                        TableRow(
                          decoration: BoxDecoration(
                              color: appStateSettings["materialYou"]
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : getColor(context, "lightDarkAccentHeavy")),
                          children: <Widget>[
                            for (dynamic entry in firstEntry)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11.0, vertical: 5),
                                child: TextFont(
                                  text: entry.toString(),
                                  fontSize: 15,
                                  textColor: appStateSettings["materialYou"]
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : getColor(context, "black"),
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: appStateSettings["materialYou"]
                                ? dynamicPastel(
                                    context,
                                    Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    amount: 0.2,
                                  )
                                : getColor(
                                    context, "lightDarkAccentHeavyLight")),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                runAlignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      TextFont(
                                        text: "date-format".tr(),
                                        fontSize: 15,
                                      ),
                                      TextFont(
                                        text: "example".tr() +
                                            " " +
                                            "dd/MM/yyyy HH:mm",
                                        fontSize: 12,
                                        maxLines: 5,
                                      ),
                                      TextFont(
                                        text: "date-format-note".tr(),
                                        maxLines: 5,
                                        fontSize: 12,
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                  Container(
                                    child: TextInput(
                                      labelText: "dd/MM/yyyy HH:mm",
                                      padding: EdgeInsets.zero,
                                      onChanged: (value) {
                                        dateFormat = value;
                                      },
                                      backgroundColor:
                                          appStateSettings["materialYou"]
                                              ? null
                                              : dynamicPastel(
                                                  context,
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                                  amount: 0.2,
                                                ).withOpacity(0.4),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (dynamic key in assignedColumns.keys)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: appStateSettings["materialYou"]
                                ? dynamicPastel(
                                    context,
                                    Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    amount: 0.2,
                                  )
                                : getColor(
                                    context, "lightDarkAccentHeavyLight"),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  runAlignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    TextFont(
                                      text: assignedColumns[key]!["displayName"]
                                          .toString()
                                          .tr()
                                          .toString()
                                          .capitalizeFirst,
                                      fontSize: 15,
                                    ),
                                    SizedBox(width: 10),
                                    DropdownSelect(
                                      compact: true,
                                      initial: assignedColumns[key]![
                                          "setHeaderValue"],
                                      items: assignedColumns[key]![
                                                  "canSelectCurrentWallet"] ==
                                              true
                                          ? ["~Current Wallet~", ...headers]
                                          : assignedColumns[key]!["required"]
                                              ? [
                                                  ...(assignedColumns[key]?[
                                                              "setHeaderValue"] ==
                                                          ""
                                                      ? [""]
                                                      : []),
                                                  ...headers
                                                ]
                                              : ["~None~", ...headers],
                                      boldedValues: [
                                        "~Current Wallet~",
                                        "~None~"
                                      ],
                                      getLabel: (label) {
                                        if (label == "~Current Wallet~") {
                                          return "~" +
                                              "current-account".tr() +
                                              "~";
                                        } else if (label == "~None~") {
                                          return "~" + "none".tr() + "~";
                                        }
                                        return label;
                                      },
                                      onChanged: (String setHeaderValue) {
                                        assignedColumns[key]![
                                            "setHeaderValue"] = setHeaderValue;
                                        assignedColumns[key]![
                                                "setHeaderIndex"] =
                                            _getHeaderIndex(
                                                headers, setHeaderValue);
                                      },
                                      backgroundColor:
                                          Theme.of(context).canvasColor,
                                      checkInitialValue: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Button(
                label: "import".tr(),
                onTap: () async {
                  try {
                    await _importEntries(
                        assignedColumns, dateFormat, fileContents);
                  } catch (e) {
                    openPopup(
                      context,
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.warning_outlined
                          : Icons.warning_rounded,
                      title: "csv-error".tr(),
                      description: "consider-csv-template".tr() + e.toString(),
                      onSubmit: () {
                        Navigator.pop(context);
                      },
                      onSubmitLabel: "ok".tr(),
                      onCancel: () {
                        importFromSheets
                            ? getGoogleSheetTemplate(context)
                            : saveSampleCSV();
                      },
                      onCancelLabel: "get-template".tr(),
                    );
                  }
                },
              )
            ],
          ),
        ),
      );
    } catch (e) {
      openPopup(
        context,
        title: "csv-error".tr(),
        description: e.toString(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.error_outlined
            : Icons.error_rounded,
        onSubmitLabel: "ok".tr(),
        onSubmit: () {
          Navigator.of(context).pop();
        },
        barrierDismissible: false,
      );
    }
  }

  Future<void> _importEntries(Map<String, Map<String, dynamic>> assignedColumns,
      String dateFormat, List<List<String>> fileContents,
      {bool noPop = false}) async {
    try {
      //Check to see if all the required parameters have been set
      for (dynamic key in assignedColumns.keys) {
        if (assignedColumns[key]!["setHeaderValue"] == "") {
          throw "Please make sure you select a parameter for each required field.";
        }
        print(assignedColumns[key]!["setHeaderIndex"]);
      }
    } catch (e) {
      throw (e.toString());
    }
    if (noPop == false) Navigator.of(context).pop();
    // Open the progress bar
    // This Widget opened will actually do the importing
    openPopupCustom(
      context,
      title: "importing-loading".tr(),
      child: ImportingEntriesPopup(
        dateFormat: dateFormat,
        assignedColumns: assignedColumns,
        fileContents: fileContents,
        next: () {
          Navigator.of(context).pop();
          openPopup(
            context,
            icon: appStateSettings["outlinedIcons"]
                ? Icons.check_circle_outline_outlined
                : Icons.check_circle_outline_rounded,
            title: "done".tr() + "!",
            description: "successfully-imported".tr() +
                " " +
                // Subtract one, since we don't count the header of the CSV as an entry
                (fileContents.length - 1).toString() +
                " " +
                "transactions".tr().toLowerCase() +
                ".",
            onSubmitLabel: "ok".tr(),
            onSubmit: () {
              Navigator.pop(context);
            },
            barrierDismissible: false,
          );
        },
      ),
      barrierDismissible: false,
    );
    return;
  }

  String determineInitialValue(List<String> headerValues, List<String> headers,
      bool required, bool? canSelectCurrentWallet) {
    for (String header in headers) {
      if (headerValues.contains(header.toLowerCase()) ||
          headerValues.contains(header) ||
          headerValues.contains(header.toLowerCase().trim())) {
        return header;
      }
    }
    if (canSelectCurrentWallet == true) {
      return "~Current Wallet~";
    }
    if (!required) {
      return "~None~";
    }
    return "";
  }

  _enterGoogleSheetURL() {
    print(DateTime.now().toString());
    openBottomSheet(
      context,
      fullSnap: true,
      PopupFramework(
        title: "enter-google-sheet-url".tr(),
        subtitle: "enter-google-sheet-url-description".tr(),
        child: Column(
          children: [
            SelectText(
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.link_outlined
                  : Icons.link_rounded,
              setSelectedText: (_) {},
              nextWithInput: (url) async {
                String? csvString;
                await openLoadingPopupTryCatch(() async {
                  String? csvURL = convertGoogleSheetsUrlToCsvUrl(url);
                  csvString = await fetchDataFromCsvUrl(csvURL);
                }, onError: (e) {
                  openPopup(
                    context,
                    title: "csv-error".tr(),
                    description: e.toString(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.error_outlined
                        : Icons.error_rounded,
                    onSubmitLabel: "ok".tr(),
                    onSubmit: () {
                      Navigator.of(context).pop();
                    },
                    barrierDismissible: false,
                  );
                });
                if (csvString != null) {
                  _assignColumns(csvString!, importFromSheets: true);
                }
              },
              placeholder:
                  "https://docs.google.com/spreadsheets/d/1Eiib2fiaC8SNdau8T8TBQql-wyWXVYOLJY-7Ycuky4I/edit?usp=sharing",
              autoFocus: false,
              requestLateAutoFocus: true,
            ),
          ],
        ),
      ),
    );
    // Fix over-scroll stretch when keyboard pops up quickly
    Future.delayed(Duration(milliseconds: 100), () {
      bottomSheetControllerGlobal.scrollTo(0,
          duration: Duration(milliseconds: 100));
    });
  }

  String? convertGoogleSheetsUrlToCsvUrl(String googleSheetsUrl) {
    List<String> parts = googleSheetsUrl.split("/");
    int index = parts.indexOf("d");
    if (index != -1 && index + 1 < parts.length) {
      String spreadsheetId = parts[index + 1];
      String csvUrl =
          "https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv";
      return csvUrl;
    }
    throw ("Error parsing URL");
  }

  Future<String?> fetchDataFromCsvUrl(String? csvUrl) async {
    if (csvUrl == null) throw ("URL Parsing error.");
    final response = await http.get(Uri.parse(csvUrl));
    if (response.statusCode == 200) {
      String data = response.body;
      return data;
    } else {
      throw ("HTTP Request failed with status code: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainer(
          onTap: () async {
            String? csvString = await _getCSVStringFromBackupFile();
            if (csvString != null) {
              _assignColumns(csvString);
            }
          },
          title: "import-csv".tr(),
          // description: "import-csv-description".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.file_open_outlined
              : Icons.file_open_rounded,
          afterWidget: LowKeyButton(
            onTap: () async {
              saveSampleCSV();
            },
            extraWidget: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.download_outlined
                    : Icons.download_rounded,
                size: 18,
                color: getColor(context, "black").withOpacity(0.5),
              ),
            ),
            text: "template".tr(),
          ),
        ),
        SettingsContainer(
          onTap: () async {
            await _enterGoogleSheetURL();
          },
          title: "import-google-sheet".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.table_chart_outlined
              : Icons.table_chart_rounded,
          afterWidget: LowKeyButton(
            onTap: () async {
              getGoogleSheetTemplate(context);
            },
            extraWidget: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.open_in_new_outlined
                    : Icons.open_in_new_rounded,
                size: 18,
                color: getColor(context, "black").withOpacity(0.5),
              ),
            ),
            text: "template".tr(),
          ),
        ),
      ],
    );
  }
}

getGoogleSheetTemplate(BuildContext context) {
  openUrl(
      "https://docs.google.com/spreadsheets/d/1Eiib2fiaC8SNdau8T8TBQql-wyWXVYOLJY-7Ycuky4I/edit?usp=sharing");
  openPopup(
    context,
    icon: appStateSettings["outlinedIcons"]
        ? Icons.table_chart_outlined
        : Icons.table_chart_rounded,
    title: "create-template-copy".tr(),
    description: "create-template-copy-description".tr(),
    onSubmit: () {
      Navigator.pop(context);
    },
    onSubmitLabel: "ok".tr(),
    onCancel: () {
      openUrl(
          "https://support.google.com/docs/answer/49114?hl=en&co=GENIE.Platform%3DDesktop#zippy=%2Cmake-a-copy-of-a-file#:~:text=Make%20a%20copy%20of%20a%20file");
    },
    onCancelLabel: "help".tr(),
  );
}

Future saveSampleCSV() async {
  await openLoadingPopupTryCatch(() async {
    List<List<dynamic>> csvData = [];
    csvData.add([
      "Date",
      "Amount",
      "Category",
      "Title",
      "Note",
    ]); // Add first row headers
    csvData.add([
      DateTime.now(),
      "-50",
      "Groceries",
      "Fruits and Vegetables",
      "Paid with cash"
    ]);
    csvData.add([
      DateTime.now(),
      "250",
      "Bills & Fees",
      "Monthly Income",
      "",
    ]);
    String csv = ListToCsvConverter().convert(csvData);
    return saveCSV(csv, "Cashew-csv-template.csv");
  });
  return;
}

class ImportingEntriesPopup extends StatefulWidget {
  const ImportingEntriesPopup({
    required this.assignedColumns,
    required this.dateFormat,
    required this.fileContents,
    required this.next,
    Key? key,
  }) : super(key: key);

  final Map<String, Map<String, dynamic>> assignedColumns;
  final String dateFormat;
  final List<List<String>> fileContents;
  final VoidCallback next;

  @override
  State<ImportingEntriesPopup> createState() => _ImportingEntriesPopupState();
}

class _ImportingEntriesPopupState extends State<ImportingEntriesPopup> {
  double currentPercent = 0;
  int currentFileLength = 0;
  int currentEntryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _importEntries(
        widget.assignedColumns, widget.dateFormat, widget.fileContents));
  }

  Future<Transaction> _importEntry(
      Map<String, Map<String, dynamic>> assignedColumns,
      String dateFormat,
      List<String> row,
      int i) async {
    String name = "";
    if (assignedColumns["name"]!["setHeaderIndex"] != -1) {
      name = row[assignedColumns["name"]!["setHeaderIndex"]].toString().trim();
    }

    double? amount;
    amount = getAmountFromString(
        (row[assignedColumns["amount"]!["setHeaderIndex"]]).toString());
    if (amount == null) throw ("Unable to parse amount");

    String note = "";
    if (assignedColumns["note"]!["setHeaderIndex"] != -1) {
      note = row[assignedColumns["note"]!["setHeaderIndex"]].toString().trim();
    }

    String categoryFk = "0";
    TransactionCategory selectedCategory;
    try {
      selectedCategory = await database.getCategoryInstanceGivenName(
          row[assignedColumns["category"]!["setHeaderIndex"]]);
    } catch (_) {
      // just make a new category, no point in checking associated titles - doesn't make much sense!

      // category not found, check titles
      // try {
      //   if (name != "") {
      //     List result = await getRelatingAssociatedTitle(name);
      //     TransactionAssociatedTitle? associatedTitle = result[0];
      //     if (associatedTitle == null) {
      //       throw ("Can't find a category that matched this title: " + name);
      //     }
      //     selectedCategory =
      //         await database.getCategoryInstance(associatedTitle.categoryFk);
      //   } else {
      //     throw ("error, just make a new category");
      //   }
      // } catch (e) {
      // print(e.toString());
      // just create a category
      int numberOfCategories =
          (await database.getTotalCountOfCategories())[0] ?? 0;
      await database.createOrUpdateCategory(
        insert: true,
        TransactionCategory(
          categoryPk: "-1",
          name: row[assignedColumns["category"]!["setHeaderIndex"]],
          dateCreated: DateTime.now(),
          dateTimeModified: null,
          order: numberOfCategories,
          income: amount > 0,
          iconName: "image.png",
          methodAdded: MethodAdded.csv,
        ),
      );
      selectedCategory = await database.getCategoryInstanceGivenName(
          row[assignedColumns["category"]!["setHeaderIndex"]]);
      // }
    }
    categoryFk = selectedCategory.categoryPk;

    if (name != "") {
      // print("attempting to add " + name);
      await addAssociatedTitles(name, selectedCategory);
    }

    String walletFk = "0";
    if (assignedColumns["wallet"]!["setHeaderIndex"] == -1) {
      walletFk = appStateSettings["selectedWalletPk"];
    } else {
      try {
        walletFk = (await database.getWalletInstanceGivenName(
                row[assignedColumns["wallet"]!["setHeaderIndex"]]))
            .walletPk;
      } catch (e) {
        throw "Wallet not found! If you want to import to the current wallet, please select '~Current Wallet~'. Details: " +
            e.toString();
      }
    }

    DateTime dateCreated;
    try {
      dateCreated =
          DateTime.parse(row[assignedColumns["date"]!["setHeaderIndex"]]);
      dateCreated = DateTime(
        dateCreated.year,
        dateCreated.month,
        dateCreated.day,
        dateCreated.hour,
        dateCreated.minute,
        dateCreated.second,
      );
    } catch (e) {
      // No custom date format entered
      if (dateFormat == "")
        throw "Failed to parse date and time! Please use the custom 'Date Format' that matches your data. \n\n Details: " +
            e.toString();
      DateFormat format =
          DateFormat(dateFormat.toString(), context.locale.toString());
      try {
        dateCreated =
            format.parse(row[assignedColumns["date"]!["setHeaderIndex"]]);
        dateCreated =
            DateTime(dateCreated.year, dateCreated.month, dateCreated.day);
      } catch (e) {
        throw "Failed to parse date and time! Please use the custom 'Date Format' that matches your data. \n\n  Details: " +
            e.toString();
      }
    }

    bool income = amount > 0;

    return Transaction(
      transactionPk: "-1",
      name: name,
      amount: amount,
      note: note,
      categoryFk: categoryFk,
      walletFk: walletFk,
      dateCreated: dateCreated,
      dateTimeModified: null,
      income: income,
      paid: true,
      skipPaid: false,
      methodAdded: MethodAdded.csv,
    );
  }

  Future<void> _importEntries(Map<String, Map<String, dynamic>> assignedColumns,
      String dateFormat, List<List<String>> fileContents) async {
    try {
      List<TransactionsCompanion> transactionsInserting = [];
      for (int i = 0; i < fileContents.length; i++) {
        if (i == 0) {
          // This is the first row where the headings are defined
          // Dont import, it is not an entry
          continue;
        }
        setState(() {
          currentPercent = i / fileContents.length * 100;
          currentEntryIndex = i;
          currentFileLength = fileContents.length;
        });
        List<String> row = fileContents[i];
        Transaction transactionToAdd =
            await _importEntry(assignedColumns, dateFormat, row, i);
        TransactionsCompanion companionToInsert =
            transactionToAdd.toCompanion(true);
        // Use auto incremented ID when inserting
        companionToInsert =
            companionToInsert.copyWith(transactionPk: Value.absent());

        transactionsInserting.add(companionToInsert);
      }
      await database.createBatchTransactionsOnly(transactionsInserting);
      widget.next();
    } catch (e) {
      openPopup(
        context,
        title: "csv-error".tr(),
        description: e.toString(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.error_outlined
            : Icons.error_rounded,
        onSubmitLabel: "ok".tr(),
        onSubmit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProgressBar(
          currentPercent: currentPercent,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 10),
        TextFont(
          fontSize: 15,
          text: currentEntryIndex.toString() +
              " / " +
              currentFileLength.toString(),
        )
      ],
    );
  }
}
