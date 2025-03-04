import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class SelectItems extends StatefulWidget {
  final List<String> initialItems;
  final List<String> items;
  final Function(List<String>)? onChanged;
  final Function(String)? onChangedSingleItem;
  final IconData? checkboxCustomIconUnselected;
  final IconData? checkboxCustomIconSelected;
  final Function(String)? displayFilter;
  final Function(String)? onLongPress;

  const SelectItems({
    Key? key,
    required this.initialItems,
    required this.items,
    this.onChanged,
    this.onChangedSingleItem,
    this.checkboxCustomIconSelected,
    this.checkboxCustomIconUnselected,
    this.onLongPress,
    this.displayFilter,
  }) : super(key: key);

  @override
  State<SelectItems> createState() => _SelectItemsState();
}

class _SelectItemsState extends State<SelectItems> {
  List<String> currentItems = [];

  @override
  void initState() {
    super.initState();
    currentItems = widget.initialItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var item in widget.items)
          Tappable(
            onLongPress: widget.onLongPress != null
                ? () => widget.onLongPress!(item)
                : null,
            borderRadius: 20,
            color: Colors.transparent,
            onTap: () {
              if (currentItems.contains(item))
                currentItems.remove(item);
              else
                currentItems.add(item);
              setState(() {});
              if (widget.onChanged != null) widget.onChanged!(currentItems);
              if (widget.onChangedSingleItem != null)
                widget.onChangedSingleItem!(item);
            },
            child: ListTile(
              title: Transform.translate(
                offset: Offset(-12, 0),
                child: TextFont(
                    fontSize: 18,
                    text: widget.displayFilter == null
                        ? item
                        : widget.displayFilter!(item)),
              ),
              dense: true,
              leading: widget.checkboxCustomIconUnselected != null &&
                      widget.checkboxCustomIconSelected != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Builder(builder: (context) {
                        bool selected = currentItems.contains(item);
                        return ScaledAnimatedSwitcher(
                          keyToWatch: selected.toString(),
                          duration: Duration(milliseconds: 400),
                          child: Opacity(
                            opacity: selected ? 1 : 0.8,
                            child: Icon(
                              selected
                                  ? widget.checkboxCustomIconSelected
                                  : widget.checkboxCustomIconUnselected,
                              size: 30,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        );
                      }),
                    )
                  : Checkbox(
                      onChanged: (_) {},
                      value: currentItems.contains(item),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
            ),
          )
      ],
    );
  }
}
