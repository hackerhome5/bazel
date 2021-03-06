import '../config/config_set.dart';

/// A generator for a `packages.bzl` macro file.
class BazelMacroFile {
  final String _packageName;
  final List<NewLocalRepository> _pubDeps;
  final BuildConfigSet _buildConfigs;

  /// Creates a new [BazelMacroFile] from [packages].
  ///
  /// Uses [resolvePath] to determine the local path for a given package.
  factory BazelMacroFile.fromPackages(
    String workspacePackage,
    Iterable<String> packages,
    BuildConfigSet buildConfigs,
    String resolvePath(String packageName),
  ) {
    final repos = packages.map/*<NewLocalRepository>*/((d) {
      return new NewLocalRepository(
        name: 'pub_$d',
        path: resolvePath(d),
      );
    });
    return new BazelMacroFile.fromRepositories(
      workspacePackage,
      new List<NewLocalRepository>.unmodifiable(repos),
      buildConfigs,
    );
  }

  /// Creates a new [BazelMacroFile] from the package name and repositories.
  BazelMacroFile.fromRepositories(
      this._packageName, this._pubDeps, this._buildConfigs);

  @override
  String toString() {
    var buffer =
        new StringBuffer('# Automatically generated by "pub run dazel".\n'
            '# DO NOT MODIFY BY HAND\n\n'
            'PUB_PACKAGE_NAME = "$_packageName"\n\n'
            '# Generated automatically for package:$_packageName|pubspec.yaml\n'
            'def dazel_init():\n');
    var repositoryRules = _buildConfigs.hasCodegen ? [_codegenRepository] : [];
    repositoryRules.addAll(_pubDeps.map((d) => '$d'));
    repositoryRules.map((r) {
      var macro = r.split('\n').map((r) => '    $r').toList();
      macro = macro.take(macro.length - 1);
      return macro.join('\n');
    }).forEach(buffer.writeln);
    return buffer.toString();
  }
}

const _codegenRepository = '''
native.local_repository(
    name = "dazel_codegen",
    path = ".dazel/codegen/",
)
''';

/// Turns a local directory into a `new_local_repository` Bazel repository.
///
/// See: https://www.bazel.io/versions/master/docs/be/workspace.html#new_local_repository
class NewLocalRepository {
  /// Name of the package.
  final String name;

  /// Local file path of the package.
  final String path;

  /// Create a `new_local_repository` macro.
  NewLocalRepository({
    this.name,
    this.path,
  });

  @override
  String toString() {
    var buffer = new StringBuffer()
      ..writeln('native.new_local_repository(')
      ..writeln('    name = "$name",')
      ..writeln('    path = "$path",')
      ..writeln('    build_file = ".dazel/$name.BUILD",')
      ..writeln(')');
    return buffer.toString();
  }
}
