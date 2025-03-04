import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/debugPage.dart';
import 'package:budget/pages/detailedChangelogPage.dart';
import 'package:budget/pages/onBoardingPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/moreIcons.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/showChangelog.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  showChangelogForce(BuildContext context) {
    showChangelog(
      context,
      forceShow: true,
      majorChangesOnly: true,
      extraWidget: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
        ),
        child: Button(
          label: "view-detailed-changelog".tr(),
          onTap: () {
            Navigator.pop(context);
            pushRoute(context, DetailedChangelogPage());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      dragDownToDismiss: true,
      title: "about".tr(),
      horizontalPadding: getHorizontalPaddingConstrained(context),
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Image(
                image: AssetImage("assets/icon/icon-small.png"),
                height: 70,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tappable(
                    borderRadius: 15,
                    onLongPress: () {
                      if (allowDebugFlags)
                        pushRoute(
                          context,
                          DebugPage(),
                        );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3, horizontal: 10),
                      child: TextFont(
                        text: globalAppName,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                      ),
                    ),
                  ),
                  Tappable(
                    borderRadius: 10,
                    onTap: () {
                      showChangelogForce(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 10),
                      child: TextFont(
                        text: getVersionString(),
                        fontSize: 14,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Tappable(
            onTap: () {
              openUrl("https://github.com/jameskokoska/Cashew");
            },
            color: appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent"),
            borderRadius: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(MoreIcons.github),
                      SizedBox(width: 10),
                      Flexible(
                        child: TextFont(
                          text: "app-is-open-source"
                              .tr(namedArgs: {"app": globalAppName}),
                          fontSize: 18,
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Button(
                  label: "view-app-intro".tr(),
                  onTap: () {
                    pushRoute(
                      context,
                      OnBoardingPage(
                        popNavigationWhenDone: true,
                        showPreviewDemoButton: false,
                      ),
                    );
                  },
                  expandedLayout: true,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Button(
                  label: "view-changelog".tr(),
                  onTap: () {
                    showChangelogForce(context);
                  },
                  expandedLayout: true,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "development-team".tr(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Tappable(
            onTap: () {
              openUrl('mailto:dapperappdeveloper@gmail.com');
            },
            color: appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent"),
            borderRadius: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
              child: Column(
                children: [
                  TextFont(
                    text: "lead-developer".tr(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                  TextFont(
                    text: "James",
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                  TextFont(
                    text: "dapperappdeveloper@gmail.com",
                    fontSize: 16,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    textColor: getColor(context, "textLight"),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Tappable(
            onTap: () {},
            color: appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent"),
            borderRadius: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
              child: Column(
                children: [
                  TextFont(
                    text: "database-designer".tr(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                  TextFont(
                    text: "YuYing",
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "graphics".tr(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        AboutInfoBox(
          title: "freepik-credit".tr(),
          link: "https://www.flaticon.com/authors/freepik",
        ),
        AboutInfoBox(
          title: "font-awesome-credit".tr(),
          link: "https://fontawesome.com/",
        ),
        AboutInfoBox(
          title: "pch-vector-credit".tr(),
          link: "https://www.freepik.com/author/pch-vector",
        ),
        Container(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "major-tools".tr(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        AboutInfoBox(
          title: "Flutter",
          link: "https://flutter.dev/",
        ),
        AboutInfoBox(
          title: "Google Cloud APIs",
          link: "https://cloud.google.com/",
        ),
        AboutInfoBox(
          title: "Drift SQL Database",
          link: "https://drift.simonbinder.eu/",
        ),
        AboutInfoBox(
          title: "FL Charts",
          link: "https://github.com/imaNNeoFighT/fl_chart",
        ),
        AboutInfoBox(
          title: "exchange-rates-api".tr(),
          link: "https://github.com/fawazahmed0/currency-api",
        ),
        Container(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "translations".tr().capitalizeFirst,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
        AboutInfoBox(
          title: "Italian",
          list: ["Thomas B."],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: TranslationsHelp(
            showIcon: false,
            backgroundColor: (appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent")),
          ),
        ),
        SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Button(
                  label: "view-licenses-and-legalese".tr(),
                  color: Theme.of(context).colorScheme.tertiary,
                  textColor: Theme.of(context).colorScheme.onTertiary,
                  expandedLayout: true,
                  onTap: () {
                    showLicensePage(
                        context: context,
                        applicationVersion: getVersionString(),
                        applicationLegalese:
                            "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE." +
                                "\n\n" +
                                "exchange-rate-notice-description".tr());
                  },
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Button(
                  label: "privacy-policy".tr(),
                  color: Theme.of(context).colorScheme.tertiary,
                  textColor: Theme.of(context).colorScheme.onTertiary,
                  expandedLayout: true,
                  onTap: () {
                    openUrl("http://cashewapp.web.app/policy.html");
                  },
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Button(
            label: "delete-all-data".tr(),
            onTap: () {
              openPopup(
                context,
                title: "erase-everything".tr(),
                description: "erase-everything-description".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.warning_outlined
                    : Icons.warning_rounded,
                onSubmit: () async {
                  Navigator.pop(context);
                  openPopup(
                    context,
                    title: "erase-everything-warning".tr(),
                    description: "erase-everything-warning-description".tr(),
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.warning_amber_outlined
                        : Icons.warning_amber_rounded,
                    onSubmit: () async {
                      Navigator.pop(context);
                      openLoadingPopup(context);
                      await Future.wait([
                        database.deleteEverything(),
                        sharedPreferences.clear()
                      ]);
                      await database.close();
                      Navigator.pop(context);
                      restartAppPopup(context);
                    },
                    onSubmitLabel: "erase".tr(),
                    onCancelLabel: "cancel".tr(),
                    onCancel: () {
                      Navigator.pop(context);
                    },
                  );
                },
                onSubmitLabel: "erase".tr(),
                onCancelLabel: "cancel".tr(),
                onCancel: () {
                  Navigator.pop(context);
                },
              );
            },
            color: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Center(
            child: TextFont(
              text: "made-in-canada".tr() + " " + "🍁",
              fontSize: 14,
              textAlign: TextAlign.center,
              maxLines: 5,
            ),
          ),
        ),
      ],
    );
  }
}

class AboutInfoBox extends StatelessWidget {
  const AboutInfoBox({
    Key? key,
    required this.title,
    this.link,
    this.list,
    this.color,
    this.padding,
  }) : super(key: key);

  final String title;
  final String? link;
  final List<String>? list;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Tappable(
        onTap: () async {
          if (link != null) openUrl(link ?? "");
        },
        onLongPress: () {
          if (link != null) copyToClipboard(link ?? "");
        },
        color: color ??
            (appStateSettings["materialYou"]
                ? dynamicPastel(
                    context, Theme.of(context).colorScheme.secondaryContainer,
                    amountLight: 0.2, amountDark: 0.6)
                : getColor(context, "lightDarkAccent")),
        borderRadius: 15,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          child: Column(
            children: [
              TextFont(
                text: title,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              SizedBox(height: 6),
              if (link != null)
                TextFont(
                  text: link ?? "",
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
              for (String item in list ?? [])
                TextFont(
                  text: item,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
