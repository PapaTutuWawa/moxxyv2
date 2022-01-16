import "dart:collection";

import "package:xml/xml.dart";

class XMLNode {
  final String tag;
  Map<String, dynamic> attributes;
  List<XMLNode> children;
  bool closeTag;
  String? text;
  bool isDeclaration;

  XMLNode({ required this.tag, this.attributes = const {}, List<XMLNode> children = const [], this.closeTag = true, this.text, this.isDeclaration = false }) : children = children;
  XMLNode.xmlns({ required this.tag, required String xmlns, Map<String, String> attributes = const {}, this.children = const [], this.closeTag = true, this.text }) : attributes = { "xmlns": xmlns, ...attributes }, isDeclaration = false;

  void addChild(XMLNode child) {
    this.children.add(child);
  }
  
  String renderAttributes() {
    return this.attributes.keys.map((key) {
        final value = this.attributes[key]!;
        assert(value is String || value is int);
        if (value is String) {
          return "$key='${value}'";
        } else {
          return "$key=${value.toString()}";
        }
    }).join(" ");
  }
  
  String toXml() {
    final decl = this.isDeclaration ? "?" : "";
    if (this.children.isEmpty) {
      if (this.text != null && this.text!.isNotEmpty) {
        final attrString = this.attributes.isEmpty ? "" : " " + this.renderAttributes();
        return "<${this.tag}${attrString}>${this.text}</${this.tag}>";
      } else {
        return "<${decl}${this.tag} ${this.renderAttributes()}" + (this.closeTag ? " />" : "${decl}>");
      } 
    } else { 
      final String childXml = this.children.map((child) => child.toXml()).join();
      final xml = "<${decl}${this.tag} ${this.renderAttributes()}${decl}>${childXml}";
      return xml + (this.closeTag ? "</${this.tag}>" : "");
    }
  }

  XMLNode? firstTag(String tag, { String? xmlns}) {
    try {
      return this.children.firstWhere((node) {
          if (xmlns != null) {
            return node.tag == tag && node.attributes["xmlns"] == xmlns;
          }

          return node.tag == tag;
      });
    } catch(e) {
      return null;
    }
  }

  List<XMLNode> findTags(String tag) {
    return this.children.where((element) => element.tag == tag).toList();
  }

  String innerText() {
    return this.text ?? "";
  }

  /// Just for testing purposes
  static XMLNode fromString(String str) {
    return XMLNode.fromXmlElement(
      XmlDocument.parse(str).firstElementChild!
    );
  }

  // Because this API is better ;)
  static XMLNode fromXmlElement(XmlElement element) {
    Map<String, String> attributes = Map();

    element.attributes.forEach((attribute) {
        attributes[attribute.name.qualified] = attribute.value;
    });

    if (element.childElements.length == 0) {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        text: element.innerText
      );
    } else {
      return XMLNode(
        tag: element.name.qualified,
        attributes: attributes,
        children: element.childElements.toList().map((e) => XMLNode.fromXmlElement(e)).toList()
      );
    }
  }
}
