import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/data/service/segment_service.dart';
import 'package:karyo_wise/main.dart';
import 'package:karyo_wise/pages/annotation_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  List<Metaphase> _metaphaseList = [];
  late Map<String, bool> _buttonStates;
  bool _isLoading = true;
  Metaphase? _clickedMetaphase;

  @override
  void initState() {
    super.initState();
    _loadMetaphaseImages();
  }

  Future<void> _loadMetaphaseImages() async {
    final segmentService = SegmentService();
    _metaphaseList = (await segmentService.getMetaphaseImages())!;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // const XTypeGroup typeGroup = XTypeGroup(
    //   label: 'images',
    //   extensions: <String>['jpg', 'png'],
    // );

    // void openImage() {
    //   Future<XFile?> file =
    //       openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    //   file.then((value) => {
    //         setState(() {
    //           imagePath = value != null ? value.path : '';
    //           if (value != null) {
    //             navigateToAnnotations(context);
    //           }
    //         })
    //       });
    // }

    List<CommandBarItem> startCommandBarItems = <CommandBarItem>[
      CommandBarBuilderItem(
        builder: (context, mode, w) => Tooltip(
          message: "Import metaphase images",
          child: w,
        ),
        wrappedItem: CommandBarButton(
          icon: const Icon(FluentIcons.folder_open_20_regular, size: 20),
          label: const Text('Import'),
          onPressed: () {
            // openImage();
          },
        ),
      ),
    ];

    List<NavigationPaneItem> items = [
      PaneItem(
          key: const ValueKey('/'),
          icon: const Icon(FluentIcons.home_20_regular, size: 20),
          title: const Text('Home'),
          body: Stack(children: [
            ScaffoldPage(
                padding: EdgeInsets.zero,
                header: CommandBarCard(
                    child: CommandBar(
                        overflowBehavior: CommandBarOverflowBehavior.clip,
                        primaryItems: startCommandBarItems)),
                content: GridView.count(
                  childAspectRatio: 0.9,
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: 6,
                  children: List.generate(_metaphaseList.length, (index) {
                    var metaphase = _metaphaseList.elementAt(index);
                    return GestureDetector(
                        onTap: () {
                          navigateToAnnotations(context);
                          _clickedMetaphase = metaphase;
                        },
                        child: Card(
                            margin: const EdgeInsets.all(20.0),
                            child: Column(children: [
                              Image.network(
                                metaphase.url,
                                fit: BoxFit.contain,
                              ),
                              Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1} - ${metaphase.name}',
                                    textAlign: TextAlign.center,
                                    style: FluentTheme.of(context)
                                        .typography
                                        .subtitle,
                                  )),
                            ])));
                  }),
                )),
            Center(
                child: Visibility(
                    visible: _isLoading, child: const ProgressRing()))
          ]),
          onTap: () {
            final path = const ValueKey('/').value;
            if (GoRouterState.of(context).uri.toString() != path) {
              context.go(path);
            }
          }),
      PaneItem(
          key: const ValueKey('/annotations'),
          icon: const Icon(FluentIcons.hand_draw_20_regular, size: 20),
          title: const Text('Annotation'),
          body: AnnotationPage(
            metaphase: _clickedMetaphase,
          ),
          onTap: () {
            navigateToAnnotations(context);
          }),
    ];

    List<NavigationPaneItem> footerItems = [
      PaneItem(
        key: const ValueKey('/settings'),
        icon: const Icon(FluentIcons.settings_20_regular, size: 20),
        title: const Text('Settings'),
        body: const SizedBox.shrink(),
      )
    ];

    int calculateSelectedIndex(BuildContext context) {
      final location = GoRouterState.of(context).uri.toString();
      int indexOriginal = items
          .where((item) => item.key != null)
          .toList()
          .indexWhere((item) => item.key == Key(location));

      if (indexOriginal == -1) {
        int indexFooter = footerItems
            .where((element) => element.key != null)
            .toList()
            .indexWhere((element) => element.key == Key(location));
        if (indexFooter == -1) {
          return 0;
        }
        return items.where((element) => element.key != null).toList().length +
            indexFooter;
      } else {
        return indexOriginal;
      }
    }

    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text(appTitle),
      ),
      pane: NavigationPane(
          toggleable: false,
          selected: calculateSelectedIndex(context),
          displayMode: PaneDisplayMode.compact,
          indicator: const StickyNavigationIndicator(),
          items: items,
          footerItems: footerItems),
    );
  }

  void navigateToAnnotations(BuildContext context) {
    final path = const ValueKey('/annotations').value;
    if (GoRouterState.of(context).uri.toString() != path) {
      context.go(path);
    }
  }
}
