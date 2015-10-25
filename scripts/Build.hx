import sys.io.File;
import sys.FileSystem;
import sys.io.Process;

using StringTools;

typedef HXCPPOptions = {
    @:optional var hxcpp: String;
}

typedef CMDResult = {
    var stderr: String;
    var stdout: String;
    var code: Int;
}

typedef BuildConfig = {
    var export_ndll_dir: String;
    var build_dir: String;
    var target_build_dir: String;
    var target: String;
    var archs: Array<String>;
    var debug_build: Bool;
    var no_compilation: Bool;
    var scriptable_build: Bool;
    var lib_name: String;
    var lib_dir: String;
    var runtime_dir: String;
    var deps_dir: String;
    var args: Array<String>;
}

class Build
{

    // -- Config
    //

    static var config:BuildConfig = {
        export_ndll_dir: 'libs',
        build_dir: 'build',
        target: null,
        target_build_dir: null,
        archs: null,
        no_compilation: false,
        debug_build: false,
        scriptable_build: false,
        lib_name: 'HXCPPRuntime',
        lib_dir: null,
        runtime_dir: null,
        deps_dir: 'deps',
        args: []
    };

    // -- Main
    //

    public static function main() {
        cd('..');
        config.runtime_dir = Sys.getCwd();
        config.lib_dir = Sys.getCwd();

        var args = Sys.args();
        if (args.length > 0 && args[0] == 'build.cppia') {
            args.shift();
        }
        config.args = args;

            // Print current build options
        log('Build haxe project with options: ' + args.join(' '));

            // Configure architectures to build
        var i = 0;
        for (arg in args) {
            if (arg == '--archs') {
                config.archs = args[i+1].split(',');
            }
            i++;
        }

            // Enable debug build?
        if (args.indexOf('--debug') != -1) {
            config.debug_build = true;
        }

            // Enable cppia scripting?
        if (args.indexOf('--scriptable') != -1) {
            config.scriptable_build = true;
        }

            // Disable compilation
        if (args.indexOf('--no-compilation') != -1) {
            config.no_compilation = true;
        }

            // Build another lib that depends on hxcpp runtime
        if (args.indexOf('--lib-dir') != -1) {
            config.lib_dir = args[args.indexOf('--lib-dir')+1];
                // Change directory to the lib we want to build
            cd(config.lib_dir);
        }

            // Get target
        if (args.length > 0 && args[0] != 'clean') {
            config.target = args[0];
            config.target_build_dir = get_target_build_dir();
        }

            // Set lib name
        config.lib_name = get_lib_name();
        if (config.lib_name == null) {
            log('Error: unable to extract lib name.');
            return;
        }

            // Clean?
        if (args.indexOf('clean') != -1) {
            clean();
        } else {
                // Build
            if (config.target == 'ios') {
                build_ios();
            }
        }
    }

    // -- Clean
    //

    static function clean() {
        cmd('rm', ['-rf', config.export_ndll_dir]);
        cmd('rm', ['-rf', './bin']);
    }

    // -- Build (iOS)
    //

    static function build_ios() {

            // Configure extra flags
        var extra_haxe_flags = '';
        var extra_hxcpp_flags = '';
        if (config.debug_build) {
            extra_hxcpp_flags += ' -Ddebug';
            extra_haxe_flags += ' -debug';
        } else {
            extra_haxe_flags += ' -D no-traces';
        }

        if (config.scriptable_build) {
            extra_haxe_flags += ' -D scriptable';
        }

            // Generate C++ files
        cmd('haxe build-ios.hxml -D no-compilation' + extra_haxe_flags);

            // Strip files that would be included in dependencies
        if (config.lib_name != 'HXCPPRuntime') {
            strip_files("ios");
        }

            // Stop here if we don't perform compilation
        if (config.no_compilation) {
            return;
        }

            // Compile C++
        var root_dir = Sys.getCwd();
        cd(config.target_build_dir);
        if (config.archs == null || !config.debug_build || config.archs.indexOf('armv7') != -1)
            cmd('haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_ARMV7 -DENABLE_BITCODE -Dios -DHXCPP_CPP11 -DHXCPP_CLANG'+extra_hxcpp_flags);
        if (config.archs == null || !config.debug_build || config.archs.indexOf('arm64') != -1)
            cmd('haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_ARM64 -DENABLE_BITCODE -Dios -DHXCPP_CPP11 -DHXCPP_CLANG'+extra_hxcpp_flags);
        if (config.archs == null || !config.debug_build || config.archs.indexOf('i386') != -1)
            cmd('haxelib run hxcpp Build.xml -Diphonesim -Dsimulator -DENABLE_BITCODE -Dios -DHXCPP_CPP11 -DHXCPP_CLANG'+extra_hxcpp_flags);
        if (config.archs == null || !config.debug_build || config.archs.indexOf('x86_64') != -1)
            cmd('haxelib run hxcpp Build.xml -Diphonesim -Dsimulator -DENABLE_BITCODE -Dios -DHXCPP_M64 -DHXCPP_CPP11 -DHXCPP_CLANG'+extra_hxcpp_flags);
        cd(root_dir);

            // Combine archs into destination file
        if (config.debug_build) {
            combine_ios_archs(config.build_dir + '/ios/lib' + config.lib_name + '-debug.*.a', config.export_ndll_dir+'/ios/debug/lib' + config.lib_name + '.a');
        } else {
            combine_ios_archs(config.build_dir + '/ios/lib' + config.lib_name + '.*.a', config.export_ndll_dir+'/ios/release/lib' + config.lib_name + '.a');
        }

            // Get HXCPP options
        var options = parse_hxcpp_options(join(config.target_build_dir, 'Options.txt'));

            // For each other lib, combine archs and move to destination directory
        for (lib_name in get_haxe_libs('build.hxml')) {
            var ndll_dir = get_ndll_dir(lib_name);
            if (ndll_dir != null) {
                combine_ios_archs(ndll_dir + 'iPhone/lib' + lib_name + '.*.a', config.export_ndll_dir+'/ios/lib' + lib_name + '.a');
            }
        }
    }

    /**
     Strip files from Build.xml if they are included in dependencies' Build.xml
     This ensure we won't end up with duplicate symbols everywhere.
     */
    static function strip_files(target:String) {
        log('Strip Build.xml from duplicate files included in dependencies (prevents duplicate symbols):');
        var path = join(Sys.getCwd(), config.deps_dir);
        if (!FileSystem.exists(path)) {
            return;
        }

            // Init map of files to exclude
        var to_exclude:Map<String,Bool> = new Map<String,Bool>();

            // Iterate in deps directory to find other dependencies
        for (sub_path in FileSystem.readDirectory(path)) {
            sub_path = join(path, sub_path);
                // Check if this is a haxe dependency
            if (FileSystem.exists(sub_path) && FileSystem.isDirectory(sub_path) && FileSystem.exists(join(sub_path, "build.hxml"))) {
                    // Yes, pre-compile dependency in order to have up-to-date Build.xml file
                var is_runtime = are_same_path(sub_path, config.runtime_dir);
                var build_sh = join(config.runtime_dir, "scripts/build.sh");
                var build_args = [build_sh, target, '--no-compilation'];
                if (config.scriptable_build) {
                    build_args.push('--scriptable');
                }
                if (!is_runtime) {
                    build_args.push('--lib-dir');
                    build_args.push(sub_path);
                }
                cmd('sh', build_args);

                var sub_target_build_dir = get_target_build_dir(sub_path);
                var build_xml_dir = join(sub_target_build_dir, "Build.xml");
                if (FileSystem.exists(build_xml_dir)) {
                        // Extract used files from Build.xml
                    for (file in get_included_files(build_xml_dir)) {
                        to_exclude.set(file, true);
                    }
                }
            }
        }

        var build_xml_dir = join(config.target_build_dir, "Build.xml");
        var xml:Xml = Xml.parse(File.getContent(build_xml_dir));
        var did_exclude_files:Bool = false;
        for (elements in xml.elements()) {
                // Remove files
            for (files in elements.elementsNamed("files")) {
                var to_remove:Array<Xml> = [];
                for (file in files.elementsNamed("file")) {
                    var name = file.get("name");
                    if (to_exclude.exists(name)) {
                        did_exclude_files = true;
                        log('  exclude ' + name);
                        to_remove.push(file);
                    }
                }
                for (file in to_remove) {
                        // Remove element
                    files.removeChild(file);
                }
            }
                // Remove BuildCommon.xml
            var to_remove:Array<Xml> = [];
            for (incl in elements.elementsNamed("include")) {
                var name = incl.get("name");
                if (name == "$"+"{HXCPP}/build-tool/BuildCommon.xml") {
                    did_exclude_files = true;
                    log('  exclude ' + name);
                    to_remove.push(incl);
                }
            }
            for (incl in to_remove) {
                    // Remove element
                elements.removeChild(incl);
            }
                // Add custom toolchain for lib
            var lib_xml:Xml = Xml.parse(File.getContent(join(config.runtime_dir, 'scripts/lib-target.xml')));
            var i = 0;
            for (lib_el in lib_xml.elements()) {
                if (i == 0) {
                    for (lib_sub_el in lib_el.elements()) {
                        elements.addChild(lib_sub_el);
                    }
                }
                i++;
            }
        }
        if (!did_exclude_files) {
            log('  nothing to exclude.');
        } else {
                // Save xml (and original backup)
            File.saveContent(join(config.target_build_dir, "Build.orig.xml"), File.getContent(build_xml_dir));
            File.saveContent(build_xml_dir, xml.toString());
        }
    }

    static function get_included_files(build_xml_dir):Array<String> {
        var xml:Xml = Xml.parse(File.getContent(build_xml_dir));
        var result = [];

        for (elements in xml.elements()) {
            for (files in elements.elementsNamed("files")) {
                for (file in files.elementsNamed("file")) {
                    result.push(file.get("name"));
                }
            }
        }

        return result;
    }

    static function combine_ios_archs(source:String, dest:String) {
        var args = ['-sdk', 'iphoneos', 'lipo', '-output', dest, '-create'];

            // Compute archs to combine
        for (arch_name in ['iphoneos-64', 'iphoneos-v7', 'iphonesim-64', 'iphonesim']) {
            var single_arch_source = source.replace('*', arch_name);
            if (FileSystem.exists(single_arch_source)) {
                args.push(single_arch_source);
            }
        }

            // Ensure destination directory exists
        ensure_dir(dirname(dest));
        log('add '+basename(dest));

            // Run command
        cmd('xcrun', args);
    }

    // -- Build (Common)
    //

    static function get_target_build_dir(?project_dir:String):String {
        if (project_dir == null) project_dir = config.lib_dir;

        if (FileSystem.exists(join(project_dir, "build-" + config.target + ".hxml"))) {
            var contents = File.getContent(join(project_dir, "build-" + config.target + ".hxml"));
            for (line in contents.split("\n")) {
                if (line.trim().startsWith("-cpp ")) {
                    return join(project_dir, line.trim().substr(5).trim());
                }
            }
        }
        return join(config.build_dir, "ios");
    }

    static function get_lib_name():String {
        var contents = File.getContent(join(Sys.getCwd(), "build.hxml"));
        for (line in contents.split("\n")) {
            if (line.trim().startsWith("-main ")) {
                return line.trim().substr(6).trim();
            }
        }
        return null;
    }

    static function parse_hxcpp_options(path:String) {
        var contents = File.getContent(path);
        var options:HXCPPOptions = {};
        for (line in contents.split("\n")) {
            var assign_index = line.indexOf('=');
            if (assign_index != -1) {
                var key = line.substr(0, assign_index).trim();
                var value = line.substr(assign_index + 1).trim();
                Reflect.setProperty(options, key, value);
            }
        }
        return options;
    }

    static function get_haxe_libs(hxml_path:String):Array<String> {
        var contents = File.getContent(hxml_path);
        var result = [];

        for (line in contents.split("\n")) {
            var lib_index = line.indexOf('-lib ');
            if (lib_index != -1) {
                var lib_name = line.substr(lib_index + 5).trim();
                result.push(lib_name);
            }
        }

        return result;
    }

    static function get_ndll_dir(lib_name:String):String {
        var contents = cmd_for_result('haxelib path '+lib_name).stdout;

        for (line in contents.split("\n")) {
            if (line.startsWith('-L ')) {
                return line.substr(3).trim();
            }
        }

        return null;
    }

    // -- Helpers
    //

    static function log(message:String) {
        Sys.println(message);
    }

    static function cd(directory:String) {
        Sys.setCwd(directory);
    }

    static function cp(source:String, dest:String) {
        File.copy(source, dest);
    }

    static function join(path1:String, path2:String):String {
        return (path1 + "/" + path2).replace("//", "/");
    }

    static function are_same_path(path1:String, path2:String):Bool {
        if (!path1.endsWith("/")) path1 += "/";
        if (!path2.endsWith("/")) path2 += "/";
        return (path1 == path2);
    }

    static function cmd(command:String, ?args:Array<String>) {
        if (args == null) {
            args = [];
        }
        if (command.indexOf(' ') != -1) {
            var parts = command.split(' ');
            args = args.concat(parts.slice(1));
            command = parts[0];
        }

        Sys.command(command, args);
    }

    static function cmd_for_result(command:String, ?args:Array<String>):CMDResult {
        if (args == null) {
            args = [];
        }
        if (command.indexOf(' ') != -1) {
            var parts = command.split(' ');
            args = args.concat(parts.slice(1));
            command = parts[0];
        }

        var result = {stdout: '', stderr: '', code: -1};
        var p = new Process(command, args);
        result.code = p.exitCode();
        result.stderr = p.stderr.readAll().toString();
        result.stdout = p.stdout.readAll().toString();
        return result;
    }

    static function ln() {
        log('');
    }

    static function dirname(full_path:String) {
        return full_path.substr(0, full_path.lastIndexOf('/'));
    }

    static function basename(full_path:String) {
        return full_path.substr(full_path.lastIndexOf('/') + 1);
    }

    static function ensure_dir(path:String) {
        if (!FileSystem.exists(path)) {
            FileSystem.createDirectory(path);
        }
    }

    static function read_dir(path:String) {
        return FileSystem.readDirectory(path);
    }
}
