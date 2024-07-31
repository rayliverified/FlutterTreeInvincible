import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'flutter_tree_pro.dart';

/// Enumeration for different types of data sources.
enum DataType {
  DataList,
  DataMap,
}

/// Configuration class for tree structure components.
/// Defines how tree nodes are interpreted from raw data.
class Config {
  /// Default data type of the nodes.
  final DataType dataType;

  /// Key in data map representing parent node's ID.
  final String parentId;

  /// Key in data map representing the value of a node.
  final String value;

  /// Key in data map representing the label of a node.
  final String label;

  /// Key in data map representing the unique ID of a node.
  final String id;

  /// Key in data map representing child nodes.
  final String children;

  /// Constructor with default values for tree configuration.
  const Config({
    this.dataType = DataType.DataMap,
    this.parentId = 'parentId',
    this.value = 'value',
    this.label = 'label',
    this.id = 'id',
    this.children = 'children',
  });
}

/// Logger instance for debugging.
final Logger logger = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// A StatefulWidget that renders a tree structure with interactive nodes.
class FlutterTreePro extends StatefulWidget {
  /// Data for building the tree when data type is map.
  final List<Map<String, dynamic>> treeData;

  /// Data for building the tree when data type is list.
  final List<Map<String, dynamic>> listData;

  /// Initial data for the tree when data type is map.
  final Map<String, dynamic> initialTreeData;

  /// Initial data for the tree when data type is list.
  final List<Map<String, dynamic>> initialListData;

  /// Callback function when a node is checked or unchecked.
  final Function(List<Map<String, dynamic>>) onChecked;

  /// Configuration for node structure in the tree.
  final Config config;

  /// Whether the tree nodes are expanded by default.
  final bool isExpanded;

  /// Whether the layout is right-to-left.
  final bool isRTL;

  /// Whether only a single node can be selected at a time.
  final bool isSingleSelect;

  /// Initially selected value.
  final int initialSelectValue;

  /// Constructor initializing all the properties of the tree.
  FlutterTreePro({
    Key? key,
    this.treeData = const <Map<String, dynamic>>[],
    this.initialTreeData = const <String, dynamic>{},
    this.config = const Config(),
    this.listData = const <Map<String, dynamic>>[],
    this.initialListData = const <Map<String, dynamic>>[],
    required this.onChecked,
    this.isExpanded = false,
    this.isRTL = false,
    this.isSingleSelect = false,
    this.initialSelectValue = 0,
  }) : super(key: key);

  @override
  _FlutterTreeProState createState() => _FlutterTreeProState();
}

class _FlutterTreeProState extends State<FlutterTreePro> {
  /// List of source data maps for tree nodes.
  List<Map<String, dynamic>> sourceTreeMapList = [];

  /// Currently selected value for single-select mode.
  int selectValue = 0;

  /// Map for the checkbox states.
  Map<int, String> checkedMap = {
    0: '',
    1: 'partChecked',
    2: 'checked',
  };

  /// Temporary storage for tree data to facilitate operations.
  Map<int, Map<String, dynamic>> treeMap = {};

  /// Current selected node ID for single-select mode.
  int currentSelectId = 0;

  @override
  void initState() {
    super.initState();
    currentSelectId = widget.initialSelectValue;
    initializeTree();
  }

  /// Initializes the tree structure based on the initial data and configuration.
  void initializeTree() {
    if (widget.config.dataType == DataType.DataList) {
      var list = DataUtil.convertData(widget.listData);
      sourceTreeMapList..clear()..addAll(list);
      logger.d(sourceTreeMapList.toString());
      sourceTreeMapList.forEach(factoryTreeData);
      widget.initialListData.forEach((element) {
        element['checked'] = 0;
      });
      setupInitialSelection();
    } else {
      sourceTreeMapList = widget.treeData;
      sourceTreeMapList.forEach(factoryTreeData);
    }
  }

  /// Setups the initial selection based on whether single-select is enabled.
  void setupInitialSelection() {
    if (widget.isSingleSelect) {
      for (var item in treeMap.values.toList()) {
        if (item['id'] == widget.initialSelectValue) {
          setCheckStatus(item);
          break;
        }
      }
    } else {
      for (var item in widget.initialListData) {
        for (var element in treeMap.values.toList()) {
          if (item['id'] == element['id']) {
            setCheckStatus(element);
            break;
          }
        }
        selectCheckedBox(item, initial: true);
      }
    }
  }

  /// Sets the checked status of the given item and recursively for its children.
  void setCheckStatus(Map<String, dynamic> item) {
    item['checked'] = 2;
    item['children']?.forEach(setCheckStatus);
  }

  /// Factory method to construct the tree data map from a model.
  void factoryTreeData(dynamic treeModel) {
    treeModel['open'] = widget.isExpanded;
    treeModel['checked'] = 0;
    treeMap.putIfAbsent(treeModel[widget.config.id], () => treeModel);
    treeModel[widget.config.children]?.forEach(factoryTreeData);
  }

  /// Builds the parent node widget for the tree.
  Widget buildTreeParent(Map<String, dynamic> sourceTreeMap) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onOpenNode(sourceTreeMap),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: 20, top: 15),
            child: Column(
              children: [
                buildNodeRow(sourceTreeMap),
                if (sourceTreeMap['open'] ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: buildTreeNode(sourceTreeMap),
                  )
                else
                  SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a row widget for a node in the tree.
  Widget buildNodeRow(Map<String, dynamic> node) {
    return Row(
      textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
      children: [
        if (node[widget.config.children]?.isNotEmpty ?? false)
          Icon(
            node['open']
                ? Icons.keyboard_arrow_down_rounded
                : (widget.isRTL
                ? Icons.keyboard_arrow_left_rounded
                : Icons.keyboard_arrow_right_rounded),
            size: 20,
          ),
        SizedBox(width: 5),
        GestureDetector(
          onTap: () => selectCheckedBox(node),
          child: buildCheckBoxIcon(node),
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            node[widget.config.label],
            textAlign: widget.isRTL ? TextAlign.end : TextAlign.start,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Builds a list of child node widgets for a parent node.
  List<Widget> buildTreeNode(Map<String, dynamic> data) {
    return data[widget.config.children]?.map<Widget>((e) => GestureDetector(
      onTap: () => onOpenNode(e),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 20, top: 15),
        child: Column(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildNodeRow(e),
            if (e['open'] ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: buildTreeNode(e),
              )
            else
              SizedBox.shrink(),
          ],
        ),
      ),
    ))?.toList() ?? [];
  }

  /// Builds the appropriate checkbox icon for a node based on its checked state.
  Icon buildCheckBoxIcon(Map<String, dynamic> e) {
    return widget.isSingleSelect
        ? _buildSingleSelectIcon(e)
        : _buildMultiSelectIcon(e);
  }

  Icon _buildSingleSelectIcon(Map<String, dynamic> e) {
    if (e['children'] == null || e['children'].isEmpty) {
      return Icon(
        currentSelectId == e['id']
            ? Icons.check_box
            : Icons.check_box_outline_blank,
        color: currentSelectId == e['id'] ? Colors.blue : Colors.grey,
      );
    } else {
      return Icon(
        Icons.check_box_outline_blank,
        color: Colors.grey,
      );
    }
  }

  Icon _buildMultiSelectIcon(Map<String, dynamic> e) {
    switch (e['checked'] ?? 0) {
      case 0:
        return Icon(Icons.check_box_outline_blank, color: Colors.grey);
      case 1:
        return Icon(Icons.indeterminate_check_box, color: Colors.blue);
      case 2:
        return Icon(Icons.check_box, color: Colors.blue);
      default:
        return Icon(Icons.remove);
    }
  }

  /// Handles node opening or closing.
  void onOpenNode(Map<String, dynamic> model) {
    if ((model[widget.config.children] ?? []).isEmpty) return;
    setState(() {
      model['open'] = !model['open'];
    });
  }

  /// Handles selection of a node.
  void selectNode(Map<String, dynamic> dataModel) {
    setState(() {
      selectValue = dataModel['value'];
    });
  }

  /// Toggles the checked state of a node and updates the UI.
  void selectCheckedBox(Map<String, dynamic> dataModel, {bool initial = false}) {
    if (widget.isSingleSelect) {
      _handleSingleSelect(dataModel, initial);
    } else {
      _handleMultiSelect(dataModel, initial);
    }
  }

  /// Handles single selection logic.
  void _handleSingleSelect(Map<String, dynamic> dataModel, bool initial) {
    if (dataModel['children'] != null && dataModel['children'].isNotEmpty) {
      return;
    }
    currentSelectId = dataModel['id'];
    if (!initial) {
      widget.onChecked([dataModel]);
    }
  }

  /// Handles multi-selection logic.
  void _handleMultiSelect(Map<String, dynamic> dataModel, bool initial) {
    int checked = dataModel['checked'];
    _toggleCheckState(dataModel, checked);

    if (dataModel[widget.config.parentId] != null) {
      updateParentNode(dataModel);
    }
    setState(() {
      sourceTreeMapList = sourceTreeMapList;
    });

    List<Map<String, dynamic>> checkedItems = _getCheckedItems(initial);
    if (!initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChecked(checkedItems);
      });
    }
  }

  /// Toggles the checked state for a node and its children recursively.
  void _toggleCheckState(Map<String, dynamic> dataModel, int checked) {
    var stack = MStack();
    stack.push(dataModel);
    while (stack.top > 0) {
      Map<String, dynamic> node = stack.pop();
      node['checked'] = checked == 2 ? 0 : 2;
      node[widget.config.children]?.forEach(stack.push);
    }
  }

  /// Retrieves the list of checked items.
  List<Map<String, dynamic>> _getCheckedItems(bool initial) {
    List<Map<String, dynamic>> checkedItems = [];
    sourceTreeMapList.forEach((element) {
      checkedItems.addAll(getCheckedItems(element, initial: initial));
    });
    return checkedItems;
  }

  /// Gets checked items recursively using a stack for depth-first search.
  List<Map<String, dynamic>> getCheckedItems(Map<String, dynamic> sourceTreeMap, {bool initial = false}) {
    var stack = MStack();
    List<Map<String, dynamic>> checkedList = [];
    stack.push(sourceTreeMap);
    while (stack.top > 0) {
      var node = stack.pop();
      if (node['checked'] == 2 && (node[widget.config.children] ?? []).isEmpty) {
        checkedList.add(node);
      }
      node[widget.config.children]?.forEach(stack.push);
    }
    return checkedList;
  }

  /// Updates the parent node's checked state based on the state of its children.
  void updateParentNode(Map<String, dynamic> dataModel) {
    var parent = treeMap[dataModel[widget.config.parentId]];
    if (parent == null) return;
    int checkLen = 0;
    bool partChecked = false;
    for (var item in (parent[widget.config.children] ?? [])) {
      if (item['checked'] == 2) {
        checkLen++;
      } else if (item['checked'] == 1) {
        partChecked = true;
        break;
      }
    }

    if (checkLen == (parent[widget.config.children] ?? []).length) {
      parent['checked'] = 2;
    } else if (partChecked || (checkLen > 0 && checkLen < (parent[widget.config.children] ?? []).length)) {
      parent['checked'] = 1;
    } else {
      parent['checked'] = 0;
    }

    if (treeMap[parent[widget.config.parentId]] != null) {
      updateParentNode(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: sourceTreeMapList.map<Widget>((e) => buildTreeParent(e)).toList(),
        ),
      ),
    );
  }
}
