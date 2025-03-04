import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/countNumber.dart';
import 'package:budget/widgets/globalSnackBar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/saveBottomButton.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/currencyPicker.dart';
import 'package:budget/widgets/transactionEntry/incomeAmountArrow.dart';
import 'package:budget/widgets/transactionEntry/transactionEntryAmount.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';

import '../widgets/sliverStickyLabelDivider.dart';
import 'exchangeRatesPage.dart';

class AddWalletPage extends StatefulWidget {
  AddWalletPage({
    Key? key,
    this.wallet,
    required this.routesToPopAfterDelete,
  }) : super(key: key);

  //When a wallet is passed in, we are editing that wallet
  final TransactionWallet? wallet;
  final RoutesToPopAfterDelete routesToPopAfterDelete;

  @override
  _AddWalletPageState createState() => _AddWalletPageState();
}

class _AddWalletPageState extends State<AddWalletPage> {
  bool? canAddWallet;

  String? selectedTitle;
  Color? selectedColor;
  String? selectedIconName;
  Map<String, dynamic> currencies = {};
  bool customCurrencyIcon = false;
  String? searchCurrency = "";
  String selectedCurrency = "usd"; //if no currency selected use empty string
  int selectedDecimals = 2;
  FocusNode _titleFocusNode = FocusNode();

  void setSelectedTitle(String title) {
    setState(() {
      selectedTitle = title;
    });
    determineBottomButton();
    return;
  }

  void setSelectedColor(Color? color) {
    selectedColor = color;
    determineBottomButton();
    return;
  }

  void setSelectedCurrency(String currencyKey) {
    setState(() {
      selectedCurrency = currencyKey;
    });
    determineBottomButton();
    return;
  }

  Future addWallet() async {
    print("Added wallet");
    await database.createOrUpdateWallet(
        insert: widget.wallet == null, await createTransactionWallet());
    Navigator.pop(context);
  }

  Future<TransactionWallet> createTransactionWallet() async {
    int numberOfWallets = (await database.getTotalCountOfWallets())[0] ?? 0;
    return TransactionWallet(
      walletPk: widget.wallet != null ? widget.wallet!.walletPk : "-1",
      name: selectedTitle ?? "",
      colour: toHexString(selectedColor),
      dateCreated:
          widget.wallet != null ? widget.wallet!.dateCreated : DateTime.now(),
      dateTimeModified: null,
      order: widget.wallet != null ? widget.wallet!.order : numberOfWallets,
      currency: selectedCurrency,
      decimals: selectedDecimals,
    );
  }

  void populateCurrencies() {
    Future.delayed(Duration.zero, () async {
      setState(() {
        //Set to false because we can't save until we made some changes
        canAddWallet = false;
        currencies = currenciesJSON;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      //We are editing a wallet
      //Fill in the information from the passed in wallet
      //Outside of future.delayed because of textinput when in web mode initial value
      selectedTitle = widget.wallet!.name;
      selectedColor = widget.wallet!.colour == null
          ? null
          : HexColor(widget.wallet!.colour);
      selectedCurrency = widget.wallet!.currency ?? "usd";
      selectedDecimals = widget.wallet!.decimals;
    }
    populateCurrencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  determineBottomButton() {
    if (selectedTitle != null && selectedCurrency != "") {
      if (canAddWallet != true)
        this.setState(() {
          canAddWallet = true;
        });
    } else {
      if (canAddWallet != false)
        this.setState(() {
          canAddWallet = false;
        });
    }
  }

  void searchCurrencies(String searchTerm) async {
    if (searchTerm == "") {
      populateCurrencies();
    } else {
      Map<String, dynamic> outCurrencies = {};
      for (String key in currenciesJSON.keys) {
        dynamic currency = currenciesJSON[key];
        if ((currency["CountryName"] != null &&
                currency["CountryName"]
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase())) ||
            (currency["Currency"] != null &&
                currency["Currency"]
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase())) ||
            (currency["Code"] != null &&
                currency["Code"]
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase()))) {
          outCurrencies[key] = currency;
        }
      }
      setState(() {
        currencies = outCurrencies;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> currencyList = [];
    for (int index = 0; index < currencies.keys.length; index++) {
      String key = currencies.keys.toList()[index];
      currencyList.add(Padding(
        padding: const EdgeInsets.only(left: 18.0, right: 18, bottom: 5),
        child: Tappable(
          color: selectedCurrency == key
              ? Theme.of(context).colorScheme.secondaryContainer
              : getColor(context, "lightDarkAccent"),
          borderRadius: 13,
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
            setSelectedCurrency(key);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextFont(
                        text: currencies[key]?["CountryName"] ??
                            currencies[key]?["Currency"]),
                  ],
                ),
                Row(
                  children: [
                    TextFont(
                        text: currencies[key]["Symbol"] +
                            " " +
                            currencies[key]["Code"]),
                  ],
                )
              ],
            ),
          ),
        ),
      ));
    }

    return WillPopScope(
      onWillPop: () async {
        if (widget.wallet != null) {
          discardChangesPopup(
            context,
            previousObject: widget.wallet,
            currentObject: await createTransactionWallet(),
          );
        } else {
          discardChangesPopup(context, forceShow: true);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          //Minimize keyboard when tap non interactive widget
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: PageFramework(
          resizeToAvoidBottomInset: true,
          dragDownToDismiss: true,
          horizontalPadding: getHorizontalPaddingConstrained(context),
          title:
              widget.wallet == null ? "add-account".tr() : "edit-account".tr(),
          onBackButton: () async {
            if (widget.wallet != null) {
              discardChangesPopup(
                context,
                previousObject: widget.wallet,
                currentObject: await createTransactionWallet(),
              );
            } else {
              discardChangesPopup(context, forceShow: true);
            }
          },
          onDragDownToDismiss: () async {
            if (widget.wallet != null) {
              discardChangesPopup(
                context,
                previousObject: widget.wallet,
                currentObject: await createTransactionWallet(),
              );
            } else {
              discardChangesPopup(context, forceShow: true);
            }
          },
          actions: [
            IconButton(
              padding: EdgeInsets.all(15),
              tooltip: "info".tr(),
              onPressed: () {
                openPopup(
                  context,
                  title: "exchange-rate-notice".tr(),
                  description: "exchange-rate-notice-description".tr(),
                  icon: Icons.info,
                  onCancel: () {
                    Navigator.pop(context);
                  },
                  onCancelLabel: "ok".tr(),
                  onSubmit: () {
                    Navigator.pop(context);
                    pushRoute(context, ExchangeRates());
                  },
                  onSubmitLabel: "exchange-rates".tr(),
                );
              },
              icon: Icon(Icons.info),
            ),
            ...(widget.wallet != null &&
                    widget.wallet!.walletPk != "0" &&
                    widget.routesToPopAfterDelete !=
                        RoutesToPopAfterDelete.PreventDelete
                ? [
                    IconButton(
                      padding: EdgeInsets.all(15),
                      tooltip: "delete-account".tr(),
                      onPressed: () {
                        deleteWalletPopup(
                          context,
                          wallet: widget.wallet!,
                          routesToPopAfterDelete: widget.routesToPopAfterDelete,
                        );
                      },
                      icon: Icon(appStateSettings["outlinedIcons"]
                          ? Icons.delete_outlined
                          : Icons.delete_rounded),
                    )
                  ]
                : [])
          ],
          overlay: Align(
            alignment: Alignment.bottomCenter,
            child: selectedTitle == "" || selectedTitle == null
                ? SaveBottomButton(
                    label: "set-name".tr(),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      Future.delayed(Duration(milliseconds: 100), () {
                        _titleFocusNode.requestFocus();
                      });
                    },
                    disabled: false,
                  )
                : SaveBottomButton(
                    label: widget.wallet == null
                        ? "add-account".tr()
                        : "save-changes".tr(),
                    onTap: () async {
                      await addWallet();
                    },
                    disabled: !(canAddWallet ?? false),
                  ),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextInput(
                  autoFocus: kIsWeb && getIsFullScreen(context),
                  focusNode: _titleFocusNode,
                  labelText: "name-placeholder".tr(),
                  bubbly: false,
                  initialValue: selectedTitle,
                  onChanged: (text) {
                    setSelectedTitle(text);
                  },
                  padding: EdgeInsets.only(left: 7, right: 7),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  topContentPadding: 20,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 14),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 65,
                child: SelectColor(
                  horizontalList: true,
                  selectedColor: selectedColor,
                  setSelectedColor: setSelectedColor,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            SliverToBoxAdapter(
              child: widget.wallet == null
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 10,
                      ),
                      child: Button(
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.library_add_outlined
                            : Icons.library_add_rounded,
                        label: "correct-total-balance".tr(),
                        onTap: () async {
                          TransactionWallet wallet =
                              await createTransactionWallet();
                          openBottomSheet(
                            context,
                            fullSnap: true,
                            PopupFramework(
                              title: "enter-amount".tr(),
                              underTitleSpace: false,
                              child: CorrectBalancePopup(wallet: wallet),
                            ),
                          );
                        },
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: widget.wallet == null ||
                      widget.routesToPopAfterDelete ==
                          RoutesToPopAfterDelete.PreventDelete
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 10,
                      ),
                      child: Button(
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.compare_arrows_outlined
                            : Icons.compare_arrows_rounded,
                        label: "transfer-balance".tr(),
                        onTap: () async {
                          if (widget.wallet != null)
                            openBottomSheet(
                              context,
                              fullSnap: true,
                              PopupFramework(
                                title: "enter-amount".tr(),
                                underTitleSpace: false,
                                child: TransferBalancePopup(
                                    wallet: widget.wallet!),
                              ),
                            );
                        },
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: widget.wallet == null ||
                      widget.routesToPopAfterDelete ==
                          RoutesToPopAfterDelete.PreventDelete
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 10,
                      ),
                      child: Button(
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.merge_outlined
                            : Icons.merge_rounded,
                        label: "merge-account".tr(),
                        onTap: () async {
                          if (widget.wallet != null)
                            mergeWalletPopup(
                              context,
                              walletOriginal: widget.wallet!,
                              routesToPopAfterDelete:
                                  widget.routesToPopAfterDelete,
                            );
                        },
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
            ),

            SliverStickyLabelDivider(
              info: "select-currency".tr(),
              sliver: ColumnSliver(children: [
                SizedBox(height: 10),
                CurrencyPicker(
                  onSelected: setSelectedCurrency,
                  initialCurrency: selectedCurrency,
                  onHasFocus: () {
                    // Disable scroll when focus - because iOS header height is different than that of Android.
                    // Future.delayed(Duration(milliseconds: 500), () {
                    //   addWalletPageKey.currentState?.scrollTo(250);
                    // });
                  },
                  extraButton: Row(
                    children: [
                      SizedBox(width: 10),
                      ButtonIcon(
                          onTap: () {
                            openBottomSheet(
                              context,
                              PopupFramework(
                                title: "decimal-precision".tr(),
                                child: SelectAmountValue(
                                  amountPassed: selectedDecimals.toString(),
                                  setSelectedAmount: (amount, _) {
                                    selectedDecimals = amount.toInt();
                                    if (amount > 10) {
                                      selectedDecimals = 10;
                                    } else if (amount < 0) {
                                      selectedDecimals = 0;
                                    }
                                    setState(() {});
                                  },
                                  next: () async {
                                    determineBottomButton();
                                    Navigator.pop(context);
                                  },
                                  nextLabel: "set-amount".tr(),
                                ),
                              ),
                            );
                          },
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.more_horiz_outlined
                              : Icons.more_horiz_rounded),
                      SizedBox(width: 18),
                    ],
                  ),
                ),
              ]),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 65)),
            // SliverToBoxAdapter(
            //   child: KeyboardHeightAreaAnimated(),
            // ),
          ],
        ),
      ),
    );
  }
}

class CorrectBalancePopup extends StatefulWidget {
  const CorrectBalancePopup({required this.wallet, super.key});
  final TransactionWallet wallet;

  @override
  State<CorrectBalancePopup> createState() => _CorrectBalancePopupState();
}

class _CorrectBalancePopupState extends State<CorrectBalancePopup> {
  double enteredAmount = 0;
  bool isNegative = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double?>(
      stream: database.watchTotalOfWalletNoConversion(
        widget.wallet.walletPk,
      ),
      builder: (context, snapshot) {
        double totalWalletAmount = snapshot.data ?? 0;
        return Column(
          children: [
            SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextFont(
                  autoSizeText: true,
                  maxLines: 1,
                  minFontSize: 16,
                  text: convertToMoney(
                    Provider.of<AllWallets>(context),
                    totalWalletAmount,
                    currencyKey: widget.wallet.currency,
                    decimals: widget.wallet.decimals,
                  ),
                  textAlign: TextAlign.center,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    appStateSettings["outlinedIcons"]
                        ? Icons.arrow_forward_outlined
                        : Icons.arrow_forward_rounded,
                  ),
                ),
                AnimatedSizeSwitcher(
                  clipBehavior: Clip.none,
                  child: TextFont(
                    key: ValueKey(enteredAmount),
                    autoSizeText: true,
                    maxLines: 1,
                    minFontSize: 16,
                    text: convertToMoney(
                      Provider.of<AllWallets>(context),
                      enteredAmount,
                      currencyKey: widget.wallet.currency,
                      decimals: widget.wallet.decimals,
                    ),
                    textAlign: TextAlign.center,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Builder(builder: (context) {
              double difference = (enteredAmount - totalWalletAmount);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  difference != 0
                      ? IncomeOutcomeArrow(
                          isIncome: difference > 0,
                          width: 15,
                        )
                      : Container(),
                  Flexible(
                    child: CountNumber(
                      count: difference.abs(),
                      duration: Duration(milliseconds: 300),
                      initialCount: (0),
                      textBuilder: (number) {
                        return TextFont(
                          text: convertToMoney(
                            Provider.of<AllWallets>(context),
                            number,
                            currencyKey: widget.wallet.currency,
                            decimals: widget.wallet.decimals,
                            finalNumber: number,
                          ),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          textColor: difference > 0 == true
                              ? getColor(context, "incomeAmount")
                              : getColor(context, "expenseAmount"),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 8),
            SelectAmountValue(
              // Rerender when has data, so that the initialValue of negative-amount if correct
              // Also render if no data, because that means the wallet is empty
              // We still want users to be able to correct the amount
              key: ValueKey(snapshot.hasData == false),
              extraWidgetAboveNumbers: SettingsContainerSwitch(
                title: "negative-amount".tr(),
                onSwitched: (value) {
                  setState(() {
                    isNegative = value;
                    if (isNegative == true)
                      enteredAmount = enteredAmount.abs() * -1;
                    else
                      enteredAmount = enteredAmount.abs();
                  });
                },
                enableBorderRadius: true,
                initialValue: totalWalletAmount < 0,
                syncWithInitialValue: false,
                runOnSwitchedInitially: true,
              ),
              showEnteredNumber: false,
              amountPassed: "0",
              setSelectedAmount: (amount, calculation) {
                setState(() {
                  if (isNegative == true)
                    enteredAmount = amount.abs() * -1;
                  else
                    enteredAmount = amount.abs();
                });
              },
              allowZero: true,
              next: () async {
                await correctWalletBalance(
                  context,
                  enteredAmount - totalWalletAmount,
                  enteredAmount,
                  widget.wallet,
                );
                Navigator.pop(context);
              },
              nextLabel: "update-total-balance".tr(),
            ),
          ],
        );
      },
    );
  }
}

Future<bool> correctWalletBalance(BuildContext context, double differenceAmount,
    double newAmount, TransactionWallet wallet) async {
  String transferString = wallet.name +
      ": " +
      convertToMoney(
        Provider.of<AllWallets>(context, listen: false),
        newAmount,
        currencyKey: wallet.currency,
        decimals: wallet.decimals,
      );

  String note = "updated-total-balance".tr() + "\n" + transferString;

  await createCorrectionTransaction(differenceAmount, wallet, note: note);

  openSnackbar(
    SnackbarMessage(
      title: "updated-total-balance".tr(),
      description: transferString,
      icon: appStateSettings["outlinedIcons"]
          ? Icons.library_add_outlined
          : Icons.library_add_rounded,
    ),
  );

  return true;
}

Future createCorrectionTransaction(double amount, TransactionWallet wallet,
    {String? note}) async {
  try {
    await database.getCategory("0").$2;
  } catch (e) {
    print(
        e.toString() + "- creating default category amount balancing category");
    int numberOfCategories =
        (await database.getTotalCountOfCategories())[0] ?? 0;

    await database.createOrUpdateCategory(
      insert: false,
      updateSharedEntry: false,
      TransactionCategory(
        categoryPk: "0",
        name: "default-category-account-amount-balancing".tr(),
        colour: toHexString(Colors.blueGrey),
        iconName: "charts.png",
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        order: numberOfCategories,
        income: false,
      ),
    );
  }

  await database.createOrUpdateTransaction(
    insert: true,
    updateSharedEntry: false,
    Transaction(
      transactionPk: "-1",
      name: "",
      amount: amount,
      note: note ?? "",
      categoryFk: "0",
      walletFk: wallet.walletPk,
      dateCreated: DateTime.now(),
      income: amount > 0,
      paid: true,
      skipPaid: false,
    ),
  );
}

class TransferBalancePopup extends StatefulWidget {
  const TransferBalancePopup({required this.wallet, super.key});
  final TransactionWallet wallet;

  @override
  State<TransferBalancePopup> createState() => _TransferBalancePopupState();
}

class _TransferBalancePopupState extends State<TransferBalancePopup> {
  double enteredAmount = 0;
  bool isNegative = false;
  late TransactionWallet walletFrom = widget.wallet;
  TransactionWallet? walletTo;

  Widget walletSelector(TransactionWallet? wallet,
      Function(TransactionWallet wallet) onSelected) {
    return Opacity(
      opacity: wallet == null ? 0.5 : 1,
      child: AnimatedSizeSwitcher(
        clipBehavior: Clip.none,
        child: Tappable(
          key: ValueKey(walletFrom.walletPk),
          color: getColor(context, "lightDarkAccentHeavyLight"),
          borderRadius: 12,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: HexColor(wallet?.colour,
                        defaultColor: Theme.of(context).colorScheme.primary)
                    .withOpacity(0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: TextFont(
                text: (wallet?.name ?? "select-account".tr()) +
                    (wallet != null
                        ? "\n" + (wallet.currency ?? "").toUpperCase()
                        : ""),
                fontSize: 17,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
          ),
          onTap: () async {
            dynamic result =
                await selectWalletPopup(context, selectedWallet: wallet);
            if (result is TransactionWallet) {
              onSelected(result);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 10,
          children: [
            walletSelector(walletFrom, (wallet) {
              setState(() {
                walletFrom = wallet;
              });
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedRotation(
                duration: Duration(milliseconds: 1200),
                turns: isNegative ? 0.5 : 1,
                curve: ElasticOutCurve(0.6),
                child: Icon(
                  appStateSettings["outlinedIcons"]
                      ? Icons.arrow_forward_outlined
                      : Icons.arrow_forward_rounded,
                ),
              ),
            ),
            walletSelector(walletTo, (wallet) {
              setState(() {
                walletTo = wallet;
              });
            }),
          ],
        ),
        SizedBox(height: 10),
        AnimatedSizeSwitcher(
          clipBehavior: Clip.none,
          child: TextFont(
            key: ValueKey(enteredAmount),
            autoSizeText: true,
            maxLines: 1,
            minFontSize: 16,
            text: convertToMoney(
              Provider.of<AllWallets>(context),
              enteredAmount
                  .abs(), //We flip the arrow instead of showing negative
              currencyKey: widget.wallet.currency,
              decimals: widget.wallet.decimals,
              addCurrencyName: true,
            ),
            textAlign: TextAlign.center,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        SelectAmountValue(
          extraWidgetAboveNumbers: SettingsContainerSwitch(
            title: "withdraw-amount".tr(),
            onSwitched: (value) {
              setState(() {
                isNegative = value;
                if (isNegative == true)
                  enteredAmount = enteredAmount.abs() * -1;
                else
                  enteredAmount = enteredAmount.abs();
              });
            },
            enableBorderRadius: true,
            initialValue: false,
            syncWithInitialValue: false,
            runOnSwitchedInitially: true,
          ),
          showEnteredNumber: false,
          amountPassed: "0",
          setSelectedAmount: (amount, calculation) {
            setState(() {
              if (isNegative == true)
                enteredAmount = amount.abs() * -1;
              else
                enteredAmount = amount.abs();
            });
          },
          allowZero: true,
          next: () async {
            if (walletTo == null) {
              dynamic result =
                  await selectWalletPopup(context, selectedWallet: walletTo);
              if (result is TransactionWallet) {
                setState(() {
                  walletTo = result;
                });
              }
              return;
            }

            String transferString =
                walletFrom.name + (isNegative ? " ← " : " → ") + walletTo!.name;

            String note = "transferred-balance".tr() + "\n" + transferString;

            AllWallets allWallets =
                Provider.of<AllWallets>(context, listen: false);

            await createCorrectionTransaction(
              enteredAmount *
                  (amountRatioFromToCurrency(
                        allWallets
                            .indexedByPk[appStateSettings["selectedWalletPk"]]!
                            .currency!,
                        allWallets.indexedByPk[walletTo!.walletPk]!.currency!,
                      ) ??
                      1),
              walletTo!,
              note: note,
            );

            await createCorrectionTransaction(
              enteredAmount *
                  -1 *
                  (amountRatioFromToCurrency(
                        allWallets
                            .indexedByPk[appStateSettings["selectedWalletPk"]]!
                            .currency!,
                        allWallets.indexedByPk[walletFrom.walletPk]!.currency!,
                      ) ??
                      1),
              walletFrom,
              note: note,
            );

            openSnackbar(
              SnackbarMessage(
                title: "transferred-balance".tr(),
                description: transferString,
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.compare_arrows_outlined
                    : Icons.compare_arrows_rounded,
              ),
            );

            Navigator.pop(context);
          },
          nextLabel:
              walletTo == null ? "select-account".tr() : "transfer-amount".tr(),
        ),
      ],
    );
  }
}
