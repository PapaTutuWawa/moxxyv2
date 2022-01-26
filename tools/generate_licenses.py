from collections import namedtuple
import yaml
import requests

ApiResponse = namedtuple("ApiResponse", [
    "name", # The library name
    "url"   # The library homepage or repository
])

def render_library(api, _license):
    return '\tLibrary(name: "{}", license: "{}", url: "{}")'.format(
        api.name,
        _license,
        api.url
    )

# Return either the homepage, repository url or throw
#
# @obj: The JSON API response dict
def homepage_wrapper(response):
    if "homepage" in response["latest"]["pubspec"]:
        return response["latest"]["pubspec"]["homepage"]
    elif "repository" in response["latest"]["pubspec"]:
        return response["latest"]["pubspec"]["repository"]

    raise Exception("No homepage or repository for " + response["name"])

# Return the ApiResponse object for a given library name
def get_library_data(pkg):
    data = requests.get("https://pub.dev/api/packages/" + pkg).json()
    return ApiResponse(data["name"], homepage_wrapper(data))

# Return the license of a given package or throw
# NOTE: One giant hack as the API does not expose this information
def get_license(pkg):
    body = requests.get("https://pub.dev/packages/" + pkg + "/license").text

    if "Apache-2.0" in body or ("Apache License" in body and "Version 2.0" in body):
        return "Apache-2.0"
    elif "BSD-3-Clause" in body:
        return "BSD-3-Clause"
    elif "MIT" in body:
        return "MIT"

    raise Exception("Unknown license for " + pkg)

# Just some wrapper functions to make the list comprehensions easier
def mklib_remote(pkg):
    print("[i] " + pkg)
    return render_library(get_library_data(pkg), get_license(pkg))
def mklib_local(api, _license):
    print("[i] " + api.name)
    return render_library(api, _license)

def main():
    with open("pubspec.yaml", "r") as f:
        pubspec = yaml.load(f.read(), Loader=yaml.Loader)

    libs = [ mklib_remote(pkg) for pkg in pubspec["dependencies"] if pkg not in ("flutter",) ]
    devlibs = [ mklib_remote(pkg) for pkg in pubspec["dev_dependencies"] if pkg not in ("flutter_test", "test",) ]
    extra = pubspec.get("extra_licenses", {})
    extralibs = [ mklib_local(ApiResponse(obj, extra[obj]["url"]), extra[obj]["license"]) for obj in extra]

    generated = '''// Generated by generate_providers.py
import "package:moxxyv2/ui/data/libraries.dart";

const List<Library> usedLibraryList = [
{}
];
'''.format(",\n".join(libs + devlibs + extralibs));

    with open("lib/ui/data/generated/licenses.dart", "w") as f:
        f.write(generated)

if __name__ == "__main__":
    main()
