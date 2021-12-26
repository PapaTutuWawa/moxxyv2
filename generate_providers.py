import json

def getFirstValue(obj):
    return list(obj.values())[0]

def renderServer(obj):
    return "\tXMPPProvider(\"{}\", \"{}\", \"{}\")".format(
        obj["jid"],
        getFirstValue(obj["website"]),
        getFirstValue(obj["legalNotice"])
    )

def main():
    with open("providers-A.json", "r") as f:
        providers = json.loads(f.read())

    generated = '''
// Generated by generate_providers.py
import "dart:collection";
import "package:moxxyv2/data/providers.dart";

final List<XMPPProvider> xmppProviderList = [
{}
];
'''.format(",\n".join([
    renderServer(obj) for obj in providers
]));

    with open("lib/data/generated/providers.dart", "w") as f:
        f.write(generated)
    #print(generated)

if __name__ == '__main__':
    main()