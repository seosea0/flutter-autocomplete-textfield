library autocomplete_textfield;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

typedef Widget AutoCompleteOverlayItemBuilder<T>(BuildContext context, T suggestion);

typedef bool Filter<T>(T suggestion, String query);

typedef InputEventCallback<T>(T data);

typedef StringCallback(String data);

class AutoCompleteTextField<T> extends StatefulWidget {
  final List<T> suggestions;
  final Filter<T>? itemFilter;
  final Comparator<T>? itemSorter;
  final StringCallback? textChanged, textSubmitted;
  final ValueSetter<bool>? onFocusChanged;
  final InputEventCallback<T>? itemSubmitted;
  final AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  final int suggestionsAmount;
  final GlobalKey<AutoCompleteTextFieldState<T>> key;
  final bool submitOnSuggestionTap, clearOnSubmit, unFocusOnItemSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int minLength;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final bool? showCursor;
  final bool autofocus;
  final bool autocorrect;
  final FormFieldValidator? validator;
  final String name;

  AutoCompleteTextField({
    required this.itemSubmitted, //Callback on item selected, this is the item selected of type <T>
    required this.key, //GlobalKey used to enable addSuggestion etc
    required this.suggestions, //Suggestions that will be displayed
    required this.itemBuilder, //Callback to build each item, return a Widget
    required this.itemSorter, //Callback to sort items in the form (a of type <T>, b of type <T>)
    required this.itemFilter, //Callback to filter item: return true or false depending on input text
    required this.name,
    this.inputFormatters,
    this.style,
    this.decoration = const InputDecoration(),
    this.textChanged, //Callback on input text changed, this is a string
    this.textSubmitted, //Callback on input text submitted, this is also a string
    this.onFocusChanged,
    this.cursorRadius,
    this.cursorWidth,
    this.cursorColor,
    this.showCursor,
    this.keyboardType = TextInputType.text,
    this.suggestionsAmount = 5, //The amount of suggestions to show, larger values may result in them going off screen
    this.submitOnSuggestionTap = true, //Call textSubmitted on suggestion tap, itemSubmitted will be called no matter what
    this.clearOnSubmit = true, //Clear autoCompleteTextfield on submit
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = false, //set the autoroccection on the internal text input field
    this.minLength = 1,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.unFocusOnItemSubmitted = true,
    this.validator,
  }) : super(key: key);

  void clear() => key.currentState!.clear();

  void addSuggestion(T suggestion) => key.currentState!.addSuggestion(suggestion);

  void removeSuggestion(T suggestion) => key.currentState!.removeSuggestion(suggestion);

  void updateSuggestions(List<T> suggestions) => key.currentState!.updateSuggestions(suggestions);

  void triggerSubmitted() => key.currentState!.triggerSubmitted();

  void updateDecoration({
    InputDecoration? decoration,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization? textCapitalization,
    TextStyle? style,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) =>
      key.currentState!.updateDecoration(
        decoration: decoration,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: style,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
      );

  FormBuilderTextField? get textFormField => key.currentState!.textFormField;

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<T>(
        suggestions,
        textChanged,
        textSubmitted,
        onFocusChanged,
        itemSubmitted,
        itemBuilder,
        itemSorter,
        itemFilter,
        suggestionsAmount,
        submitOnSuggestionTap,
        clearOnSubmit,
        minLength,
        inputFormatters,
        textCapitalization,
        decoration,
        style,
        keyboardType,
        textInputAction,
        controller,
        cursorColor,
        cursorRadius,
        cursorWidth,
        showCursor,
        focusNode,
        autofocus,
        unFocusOnItemSubmitted,
        autocorrect,
        validator,
        name,
      );
}

class AutoCompleteTextFieldState<T> extends State<AutoCompleteTextField> {
  final LayerLink _layerLink = LayerLink();

  FormBuilderTextField? textFormField;
  List<T> suggestions;
  StringCallback? textChanged, textSubmitted;
  ValueSetter<bool>? onFocusChanged;
  InputEventCallback<T>? itemSubmitted;
  AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  Comparator<T>? itemSorter;
  OverlayEntry? listSuggestionsEntry;
  List<T>? filteredSuggestions;
  Filter<T>? itemFilter;
  int suggestionsAmount;
  int minLength;
  bool submitOnSuggestionTap, clearOnSubmit, unFocusOnItemSubmitted;
  TextEditingController? controller;
  FocusNode? focusNode;
  bool autofocus;

  String currentText = "";
  Color? cursorColor;
  double? cursorWidth;
  Radius? cursorRadius;
  bool? showCursor;
  InputDecoration decoration;
  List<TextInputFormatter>? inputFormatters;
  TextCapitalization textCapitalization;
  TextStyle? style;
  TextInputType keyboardType;
  TextInputAction textInputAction;
  bool autocorrect;
  FormFieldValidator? validator;
  bool focusCreated = true;
  String name;

  AutoCompleteTextFieldState(
    this.suggestions,
    this.textChanged,
    this.textSubmitted,
    this.onFocusChanged,
    this.itemSubmitted,
    this.itemBuilder,
    this.itemSorter,
    this.itemFilter,
    this.suggestionsAmount,
    this.submitOnSuggestionTap,
    this.clearOnSubmit,
    this.minLength,
    this.inputFormatters,
    this.textCapitalization,
    this.decoration,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.cursorColor,
    this.cursorRadius,
    this.cursorWidth,
    this.showCursor,
    this.focusNode,
    this.autofocus,
    this.unFocusOnItemSubmitted,
    this.autocorrect,
    this.validator,
    this.name,
  ) {
    if (focusNode != null) {
      focusCreated = false;
    }
    focusNode ??= FocusNode();
    textFormField = FormBuilderTextField(
      name: name,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: decoration,
      style: style,
      cursorColor: cursorColor ?? Colors.black,
      showCursor: showCursor ?? true,
      cursorWidth: cursorWidth ?? 1,
      cursorRadius: cursorRadius ?? const Radius.circular(2.0),
      keyboardType: keyboardType,
      focusNode: focusNode ?? FocusNode(),
      autofocus: autofocus,
      controller: controller ?? TextEditingController(),
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      onChanged: (newText) {
        currentText = newText ?? '';
        updateOverlay(newText);

        if (textChanged != null) {
          textChanged!(newText ?? '');
        }
      },
      onTap: () {
        updateOverlay(currentText);
      },
      onSubmitted: (submittedText) => triggerSubmitted(submittedText: submittedText),
      validator: validator,
    );

    if (this.controller != null && this.controller?.text != null) {
      currentText = this.controller!.text;
    }

    this.focusNode?.addListener(() {
      if (onFocusChanged != null) {
        onFocusChanged!(this.focusNode!.hasFocus);
      }

      if (!this.focusNode!.hasFocus) {
        filteredSuggestions = [];
        updateOverlay();
      } else if (currentText != "") {
        updateOverlay(currentText);
      }
    });
  }

  void updateDecoration({
    InputDecoration? decoration,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization? textCapitalization,
    TextStyle? style,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    if (decoration != null) {
      this.decoration = decoration;
    }

    if (inputFormatters != null) {
      this.inputFormatters = inputFormatters;
    }

    if (textCapitalization != null) {
      this.textCapitalization = textCapitalization;
    }

    if (style != null) {
      this.style = style;
    }

    if (keyboardType != null) {
      this.keyboardType = keyboardType;
    }

    if (textInputAction != null) {
      this.textInputAction = textInputAction;
    }

    setState(() {
      textFormField = FormBuilderTextField(
        name: name,
        inputFormatters: this.inputFormatters,
        textCapitalization: this.textCapitalization,
        decoration: this.decoration,
        style: this.style,
        keyboardType: this.keyboardType,
        focusNode: focusNode ?? FocusNode(),
        autofocus: autofocus,
        controller: controller ?? TextEditingController(),
        textInputAction: this.textInputAction,
        onChanged: (newText) {
          currentText = newText ?? '';
          updateOverlay(newText);

          if (textChanged != null) {
            textChanged!(newText ?? '');
          }
        },
        onTap: () {
          updateOverlay(currentText);
        },
        onSubmitted: (submittedText) => triggerSubmitted(submittedText: submittedText),
        validator: validator,
      );
    });
  }

  void triggerSubmitted({submittedText}) {
    submittedText == null ? textSubmitted!(currentText) : textSubmitted!(submittedText);

    if (clearOnSubmit) {
      clear();
    }
  }

  void clear() {
    textFormField!.controller!.clear();
    currentText = "";
    updateOverlay();
  }

  void addSuggestion(T suggestion) {
    suggestions.add(suggestion);
    updateOverlay(currentText);
  }

  void removeSuggestion(T suggestion) {
    suggestions.contains(suggestion) ? suggestions.remove(suggestion) : throw "List does not contain suggestion and therefore cannot be removed";
    updateOverlay(currentText);
  }

  void updateSuggestions(List<T> suggestions) {
    this.suggestions = suggestions;
    updateOverlay(currentText);
  }

  void updateOverlay([String? query]) {
    if (listSuggestionsEntry == null && filteredSuggestions != null) {
      final Size textFieldSize = (context.findRenderObject() as RenderBox).size;
      final width = textFieldSize.width;
      final height = textFieldSize.height;
      listSuggestionsEntry = OverlayEntry(builder: (context) {
        return Positioned(
            width: width,
            child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, height),
                child: SizedBox(
                    width: width,
                    child: Card(
                        child: Column(
                      children: filteredSuggestions!.map((suggestion) {
                        return Row(children: [
                          Expanded(
                              child: TextFieldTapRegion(
                            child: InkWell(
                                child: itemBuilder!(context, suggestion),
                                onTap: () {
                                  if (!this.mounted) return;
                                  setState(() {
                                    if (submitOnSuggestionTap) {
                                      String newText = suggestion.toString();
                                      textFormField!.controller!.text = newText;
                                      if (unFocusOnItemSubmitted) {
                                        this.focusNode!.unfocus();
                                      }
                                      itemSubmitted!(suggestion);
                                      if (clearOnSubmit) {
                                        clear();
                                      }
                                    } else {
                                      String newText = suggestion.toString();
                                      textFormField!.controller!.text = newText;
                                      textChanged!(newText);
                                    }
                                  });
                                }),
                          ))
                        ]);
                      }).toList(),
                    )))));
      });
      Overlay.of(context).insert(listSuggestionsEntry!);
    }

    filteredSuggestions = getSuggestions(suggestions, itemSorter, itemFilter, suggestionsAmount, query);

    listSuggestionsEntry?.markNeedsBuild();
  }

  List<T> getSuggestions(List<T> suggestions, Comparator<T>? sorter, Filter<T>? filter, int maxAmount, String? query) {
    if (null == query || query.length < minLength) {
      return [];
    }

    suggestions = suggestions.where((item) => filter!(item, query)).toList();
    suggestions.sort(sorter);
    if (suggestions.length > maxAmount) {
      suggestions = suggestions.sublist(0, maxAmount);
    }
    return suggestions;
  }

  @override
  void dispose() {
    // if we created our own focus node and controller, dispose of them
    // otherwise, let the caller dispose of their own instances
    if (focusCreated) {
      this.focusNode?.dispose();
    }
    if (controller == null) {
      textFormField!.controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: textFormField);
  }
}

class SimpleAutoCompleteTextField extends AutoCompleteTextField<String> {
  final StringCallback? textChanged, textSubmitted;
  final int minLength;
  final ValueSetter<bool>? onFocusChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final bool? showCursor;
  final bool autofocus;
  final FormFieldValidator? validator;
  final String name;

  SimpleAutoCompleteTextField({
    TextStyle? style,
    InputDecoration decoration = const InputDecoration(),
    this.onFocusChanged,
    this.textChanged,
    this.textSubmitted,
    this.minLength = 1,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.cursorColor,
    this.cursorWidth,
    this.cursorRadius,
    this.showCursor,
    TextInputType keyboardType = TextInputType.text,
    required GlobalKey<AutoCompleteTextFieldState<String>> key,
    required List<String> suggestions,
    int suggestionsAmount = 5,
    bool submitOnSuggestionTap = true,
    bool clearOnSubmit = true,
    TextInputAction textInputAction = TextInputAction.done,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    this.validator,
    required this.name,
  }) : super(
          style: style,
          decoration: decoration,
          textChanged: textChanged,
          textSubmitted: textSubmitted,
          itemSubmitted: textSubmitted,
          keyboardType: keyboardType,
          key: key,
          suggestions: suggestions,
          itemBuilder: null,
          itemSorter: null,
          itemFilter: null,
          cursorColor: cursorColor,
          cursorWidth: cursorWidth,
          cursorRadius: cursorRadius,
          showCursor: showCursor,
          suggestionsAmount: suggestionsAmount,
          submitOnSuggestionTap: submitOnSuggestionTap,
          clearOnSubmit: clearOnSubmit,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          name: name,
        );

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<String>(
        suggestions,
        textChanged,
        textSubmitted,
        onFocusChanged,
        itemSubmitted,
        (context, item) {
          return Padding(padding: EdgeInsets.all(8.0), child: Text(item));
        },
        (a, b) {
          return a.compareTo(b);
        },
        (item, query) {
          final regex = RegExp(query, caseSensitive: false);
          return regex.hasMatch(item.toLowerCase());
        },
        suggestionsAmount,
        submitOnSuggestionTap,
        clearOnSubmit,
        minLength,
        [],
        textCapitalization,
        decoration,
        style,
        keyboardType,
        textInputAction,
        controller,
        cursorColor,
        cursorRadius,
        cursorWidth,
        showCursor,
        focusNode,
        autofocus,
        unFocusOnItemSubmitted,
        autocorrect,
        validator,
        name,
      );
}
