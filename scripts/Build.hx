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
    var archs: Array<String>;
    var debug_build: Bool;
    var scriptable_build: Bool;
    var lib_name: String;
}

class Build
{

    // -- Config
    //

    static var config:BuildConfig = {
        export_ndll_dir: 'libs',
        build_dir: 'build/hxcpp',
        archs: null,
        debug_build: false,
        scriptable_build: false,
        lib_name: 'HXCPPRuntime'
    };

    // -- Main
    //

    public static function main() {
        cd('..');

        var args = Sys.args();
        if (args.length > 0 && args[0] == 'build.cppia') {
            args.shift();
        }

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

            // Clean?
        if (args.indexOf('clean') != -1) {
            clean();
        } else {
                // Build
            if (args.length > 0 && args[0] == 'ios') {
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
        cmd('haxe build.hxml -cpp ' + config.build_dir + '/ios -D ios -D no-compilation --macro hx2objc.Macros.export(\'' + config.build_dir + '/ios/HXCPPRuntimeObjcInterface\')' + extra_haxe_flags);
            // Compile C++
        var root_dir = Sys.getCwd();
        cd(config.build_dir + '/ios');
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
        var options = parse_hxcpp_options(config.build_dir + '/ios/Options.txt');

            // For each other lib, combine archs and move to destination directory
        for (lib_name in get_haxe_libs('build.hxml')) {
            var ndll_dir = get_ndll_dir(lib_name);
            if (ndll_dir != null) {
                combine_ios_archs(ndll_dir + 'iPhone/lib' + lib_name + '.*.a', config.export_ndll_dir+'/ios/lib' + lib_name + '.a');
            }
        }
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
