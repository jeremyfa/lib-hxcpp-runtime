
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class HXCPPRuntimeBuild {

    macro static public function configure():Array<Field> {

        #if ios

        var build_xml = '
        <files id="haxe">
            <compilerflag value="-fobjc-arc" />
            <file name="../../projects/ios/HXCPPRuntime/HXCPPRuntime/HXObject.mm">
                <depend name="$'+'{HXCPP}/include/hx/Macros.h" />
                <depend name="$'+'{HXCPP}/include/hx/CFFI.h" />
            </file>
        </files>';

        var local_class = Context.getLocalClass().get();
        local_class.meta.remove(":buildXml");
        local_class.meta.add(":buildXml", [macro $v{build_xml}], Context.currentPos());

        #end

        return Context.getBuildFields();
    }
}
