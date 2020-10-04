import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:intent/intent.dart' as android_intent;
import 'package:intent/action.dart' as android_action;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share/share.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:social_share/social_share.dart';
import 'package:launch_review/launch_review.dart'; 

QuerySnapshot qn;

//AsyncMemoizer _memoizer = AsyncMemoizer();

void main() => runApp(MaterialApp(home: ListAppsPages(false)));

class ListAppsPages extends StatefulWidget {
  bool scanAgain = false;
  ListAppsPages(scanAgain) {
    this.scanAgain = scanAgain;
  }

  @override
  _ListAppsPagesState createState() => _ListAppsPagesState(this.scanAgain);
}

class _ListAppsPagesState extends State<ListAppsPages> {
  bool _showSystemApps = false;
  //bool _onlyLaunchableApps = false;
  bool _onlyLaunchableApps = true;
  bool getAppsDone = false;
  BannerAd myBanner;
  bool scanAgain = false;

  BannerAd buildBannerAd() {
    return BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: (MobileAdEvent event) {
          if (event == MobileAdEvent.loaded) {
            myBanner..show();
          }
        });
  }

  @override
  void initState() {
    super.initState();

    FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
    myBanner = buildBannerAd()..load();
  }

  @override
  void dispose() {
    myBanner.dispose();
    super.dispose();
  }

  _ListAppsPagesState(scanAgain) {
    this.scanAgain = scanAgain;
    getAppsDone = this.scanAgain;
  }

  Future getPosts() async {
    print('p2 get posts');
    var firestore = Firestore.instance;
    qn = await firestore.collection("apps").getDocuments();
    setState(() => getAppsDone = true);
    //return qn.documents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Banned Apps Remover'),
        backgroundColor: Colors.green,
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                  value: 'share',
                  child: Text('Share'),
                ),
                PopupMenuItem<String>(
                  value: 'shareOnWhatsApp',
                  child: Text('Share On WhatsApp'),
                ),
              ];
            },
            onSelected: (String key) async {
              if (key == 'share') {
                final RenderBox box = context.findRenderObject();
                Share.share("Share https://play.google.com/store/apps/details?id=com.snapchat.android",
          subject: "Sharing Is Caring",
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
              } else if(key == 'shareOnWhatsApp'){
                  SocialShare.shareWhatsapp(
                            "I'm strongly recommending banned apps remover.  \n https://play.google.com/store/apps/details?id=com.snapchat.android")
                        .then((data) {
                      print(data);
                    });
              }
            },
          )
        ],
      ),
      body: getAppsDone
          ? _ListAppsPagesContent(
              includeSystemApps: _showSystemApps,
              onlyAppsWithLaunchIntent: _onlyLaunchableApps,
              key: GlobalKey())
          : new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text('Thanks for installing me!!!',
                        style: TextStyle(fontSize: 24.0, color: Colors.green))),
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: <Widget>[
                   Icon(Icons.favorite,
      color: Colors.pink,
      size: 40.0)
                ])),
                SizedBox(height: 10.00),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text('Please make sure that VPN is stopped in your device and press scan button.',
                        style: TextStyle(fontSize: 24.0, color: Colors.green))),
                SizedBox(height: 10.0),
                Container(
                  padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: <Widget>[ new RaisedButton(
                    padding: EdgeInsets.all(10),
                    color: Colors.green,
                    child: new Text(
                      "Scan",
                      style: new TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
                    onPressed: () {
                      Center(child: CircularProgressIndicator());
                      //setState(() => getAppsDone = true);
                      getPosts();
                    })])),
              ],
            ),
    );
  }
}

class _ListAppsPagesContent extends StatelessWidget {
  final bool includeSystemApps;
  final bool onlyAppsWithLaunchIntent;

  _ListAppsPagesContent(
      {Key key,
      this.includeSystemApps: false,
      this.onlyAppsWithLaunchIntent: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Application>>(
        future: DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: includeSystemApps,
            onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent),
        builder: (BuildContext context, AsyncSnapshot<List<Application>> data) {
          if (data.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            List<Application> apps = data.data;
            List<String> bannedApps = [];
            List<String> mobileApps = [];
            List<String> matchingApps = [];
            apps
                .asMap()
                .forEach((index, item) => {mobileApps.add(item.packageName)});
            qn.documents
                .forEach((item) => {bannedApps.add(item.data['app_id'])});

            print("ok ok 1");
            matchingApps.add(mobileApps
                .where((itemApps) => bannedApps.contains(itemApps))
                .toString());
            print("ok ok 2 "+ matchingApps.length.toString());
            print("ok ok 3 "+ matchingApps[0]);
            //print("ok ok 3 "+ matchingApps[1]);

            if (matchingApps.length == 1 && matchingApps[0] == "()") {
              
                return Scrollbar(
                  child: Column(children: <Widget>[
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text('Super!!!',
                        style: TextStyle(fontSize: 24.0, color: Colors.green)
                        )
                        ),
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text('You have removed all the banned Apps.',
                        style: TextStyle(fontSize: 24.0, color: Colors.green)
                        )
                        ),
                        SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text('I have worked day and night to create this app. Please share to support.',
                        style: TextStyle(fontSize: 24.0, color: Colors.green)
                        )
                        ),
                        SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: RaisedButton(
                color: Colors.green,
                child: Text(
                  'Share on WhatsApp',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  SocialShare.shareWhatsapp(
                            "I'm strongly recommending banned apps remover.  \n https://play.google.com/store/apps/details?id=com.snapchat.android")
                        .then((data) {
                      print(data);
                    });
                }
                        )
                ),
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: RaisedButton(
                color: Colors.green,
                child: Text(
                  'Rate us on play store',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  LaunchReview.launch(androidAppId: "com.banappsremover");
                }
                        )
                ),
                SizedBox(height: 10.0),
                Container(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: RaisedButton(
                color: Colors.green,
                child: Text(
                  'Share',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {

                }
                        )
                )
              ]));
            } else {
              /*else start */
              return Scrollbar(
                child: ListView.builder(
                    itemBuilder: (BuildContext context, int position) {
                      Application app = apps[position];
                      return Column(
                        children: <Widget>[
                          qn.documents.indexWhere((qnData) =>
                                      qnData["app_id"] == app.packageName) !=
                                  -1
                              ? ListTile(
                                  leading: app is ApplicationWithIcon
                                      ? CircleAvatar(
                                          backgroundImage:
                                              MemoryImage(app.icon),
                                          backgroundColor: Colors.white,
                                        )
                                      : null,
                                  //onTap: () => DeviceApps.openApp(app.packageName),
                                  onTap: () => {
                                    //                                                    android_intent.Intent()
                                    // ..setAction(android_action.Action.ACTION_DELETE)
                                    // ..setData(Uri.parse("package:${app.packageName}"))
                                    // ..startActivity()
                                    // ..startActivityForResult().then(

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => _AppDetail(
                                                app.packageName, app.appName)))
                                  },
                                  title: Text(
                                    '${app.appName}'),
                                    subtitle: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 5),
                        child: Row(
                      children: <Widget>[
                        RaisedButton(
                          onPressed: () {
                            Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => _AppDetail(
                                                app.packageName, app.appName)));
                          },
                color: Colors.green,
                padding: EdgeInsets.all(6),
                child: Text(
                  'Check in playstore',
                  style: TextStyle(color: Colors.white),
                )
                )]
                        )
                    )]
                                    )
                                  //     '${app.appName} (${app.packageName})'),
                                  // subtitle: Text('Version: ${app.versionName}\n'
                                  //     'System app: ${app.systemApp}\n'
                                  //     'APK file path: ${app.apkFilePath}\n'
                                  //     'Data dir: ${app.dataDir}\n'
                                  //     'Installed: ${DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis).toString()}\n'
                                  //     'Updated: ${DateTime.fromMillisecondsSinceEpoch(app.updateTimeMillis).toString()}'),
                                )
                              : Divider(
                                  height: 0,
                                )
                        ],
                      );
                    },
                    itemCount: apps.length),
              );
              /*else ends */
              
            }
          }
        });
  }
}

class _AppDetail extends StatefulWidget {
  String packageName = '';
  String appName = '';

  _AppDetail(packageName, appName) {
    this.packageName = packageName;
    this.appName = appName;
  }

  @override
  __AppDetailState createState() =>
      __AppDetailState(this.packageName, this.appName);
}

class __AppDetailState extends State<_AppDetail> {
  String packageName = '';
  String appName = '';
  String _url = '';
  String _title = "Checking in play store...";
  final _key = UniqueKey();
  String _statusText = "Signing you in...";
  WebViewController _controller;
  bool isLoading = true;
  String isAppInPlayStore = "loading";

  __AppDetailState(packageName, appName) {
    this._url = 'https://play.google.com/store/apps/details?id=' + packageName;
    print(this._url);
    //setState((){
    this.packageName = packageName;
    this.appName = appName;
    //});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: LoadingOverlay(child: SingleChildScrollView(
            child: Column(children: <Widget>[
          SizedBox(height: 10.0),
          Container(
              padding: EdgeInsets.only(left: 25.0, right: 25.0),
              child: Text('Checking the app in Play Store',
                  style: TextStyle(fontSize: 24.0, color: Colors.green))),
          SizedBox(height: 10.0),
          Container(
              padding: EdgeInsets.only(left: 25.0, right: 25.0),
              child: Text(
                  'If the app is not found in play store, you can uninstall with confidence.',
                  style: TextStyle(fontSize: 18.0, color: Colors.green))),
          Container(
            padding: EdgeInsets.only(left: 25.0, right: 25.0),
            margin: EdgeInsets.only(left: 10, right: 10, top: 10),
            constraints: BoxConstraints(
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(0)),
                color: Colors.black,
                border: Border.all(color: Colors.green)),
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: WebView(
                  key: _key,
                  javascriptMode: JavascriptMode.unrestricted,
                  initialUrl: _url,
                  onWebViewCreated: (WebViewController webViewController) {
                    // Get reference to WebView controller to access it globally
                    _controller = webViewController;
                  },
                  javascriptChannels: <JavascriptChannel>[
                    // Set Javascript Channel to WebView
                    _extractDataJSChannel(context),
                  ].toSet(),
                  onPageStarted: (String url) {
                    print('Page started loading: $url');
                  },
                  onPageFinished: (String url) {
                    print('Page finished loading: $url');
                    // In the final result page we check the url to make sure  it is the last page.
                    //if (url.contains('/finalresponse.html')) {
                      setState(() => isLoading = false);
                    _controller.evaluateJavascript(
                        "(function(){Flutter.postMessage(window.document.body.outerHTML)})();");
                    //}
                  },
                )),
          )
        ])
        ), isLoading: isLoading,
        ),
        floatingActionButton: Stack(children: <Widget>[
          Align(
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: const Color(0xff03dac6),
                foregroundColor: Colors.black,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ListAppsPages(true)));
                },
                icon: Icon(Icons.scanner),
                shape: RoundedRectangleBorder(),
                label: Text('UnInstallation Done & Rescan'),
              ),
              alignment: Alignment(-0.9, 0.4)
              //alignment: Alignment.centerLeft,
              //alignment: Alignment.bottomLeft
              ),
          Align(
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: const Color(0xff03dac6),
                foregroundColor: Colors.black,
                onPressed: () => {

                    if(isAppInPlayStore=="loading"){

                      showDialog(
                                      context: context,
                                      child: new AlertDialog(
                                        title: new Text(
                                            "Please wait. It is loading."),
                                      ))

                    } else if(isAppInPlayStore=="available"){
                  showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  Center(child: Text('Alert')),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Container(
                                                    child: Text(
                                                      "App is available in play store. Means, it is not banned. Still, do you want to uninstall?",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        FlatButton(
                                                            child: Text('Yes'),
                                                            onPressed: () {
                                                              android_intent.Intent()
                    ..setAction(android_action.Action.ACTION_DELETE)
                    ..setData(Uri.parse("package:${packageName}"))
                    ..startActivity();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            }),
                                                        FlatButton(
                                                            child: Text('No'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            })
                                                      ])
                                                ],
                                              ),
                                            );
                                            }
                )
                    } else {

                      android_intent.Intent()
                    ..setAction(android_action.Action.ACTION_DELETE)
                    ..setData(Uri.parse("package:${packageName}"))
                    ..startActivity()

                    }
                
                }
              ,

                icon: Icon(Icons.delete),
                shape: RoundedRectangleBorder(),
                label: Text('UnInstall ${appName}'),
              ),
              alignment: Alignment(1, 0.8)
              //alignment: Alignment.centerRight ,
              //alignment: Alignment.bottomRight ,
              ),
        ]));
  }

  JavascriptChannel _extractDataJSChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'Flutter',
      onMessageReceived: (JavascriptMessage message) {
        String pageBody = message.message;
        if(pageBody.indexOf("We're sorry, the requested URL was not found on this server.") == -1){
          setState(() => isAppInPlayStore = "available");
        } else {
          setState(() => isAppInPlayStore = "not available");
        }
      },
    );
  }
}
