
import cpp.cppia.Host;
import sys.io.File;
import sys.FileSystem;

@:build(hx2objc.Macros.generate('HXCPPIA'))
@:keep class HXCPPRuntimeCPPIA {

    /**
     Load and run the CPPIA module at the given path
     */
    public static function run(cppiaFile:String):Void {
        if (!FileSystem.exists(cppiaFile)) {
            throw "Cannot find cppia module at `$cppiaFile`";
        }
        var source = File.getContent(cppiaFile);
        Host.run(source);
    }

}
