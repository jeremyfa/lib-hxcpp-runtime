
@:build(hx2objc.Macros.generate('HXHello'))
@:keep class HXCPPRuntimeHello {

    /**
     Just an example method to `say hello` from HXCPP
     */
    public static function say_hello(name:String):Void {
        Sys.println('Hello ' + name + '!');
    }

}
