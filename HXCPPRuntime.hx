
import hx2objc.IDHolder;

import sys.FileStat;
import sys.FileSystem;

import sys.db.Connection;
import sys.db.Manager;
import sys.db.Object;
import sys.db.RecordInfos;
import sys.db.RecordMacros;
import sys.db.ResultSet;
import sys.db.Sqlite;
import sys.db.Mysql;
import sys.db.TableCreate;
import sys.db.Transaction;
import sys.db.Types;

import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.FileSeek;
import sys.io.Process;

import sys.net.Address;
import sys.net.Host;
import sys.net.Socket;
import sys.net.UdpSocket;

import cpp.link.StaticStd;
import cpp.link.StaticRegexp;
import cpp.link.StaticSqlite;
import cpp.link.StaticZlib;
import cpp.link.StaticMysql;

import cpp.ArrayBase;
import cpp.Callable;
//import cpp.CastCharStar;
import cpp.Char;
import cpp.ConstCharStar;
import cpp.ConstPointer;
import cpp.FastIterator;
import cpp.Float32;
import cpp.Float64;
import cpp.Function;
import cpp.Int16;
import cpp.Int32;
import cpp.Int64;
import cpp.Int8;
import cpp.Lib;
import cpp.NativeArray;
import cpp.NativeString;
import cpp.NativeXml;
import cpp.Object;
import cpp.Pointer;
import cpp.Prime;
import cpp.Random;
import cpp.RawConstPointer;
import cpp.RawPointer;
import cpp.UInt16;
import cpp.UInt32;
import cpp.UInt64;
import cpp.UInt8;
import cpp.Void as CPPVoid;

import cpp.abi.Abi;
import cpp.abi.CDecl;
import cpp.abi.FastCall;
import cpp.abi.StdCall;
import cpp.abi.ThisCall;
import cpp.abi.Winapi;

import cpp.net.Poll;
import cpp.net.ThreadServer;

import cpp.rtti.FieldIntegerLookup;
import cpp.rtti.FieldNumericIntegerLookup;

import cpp.vm.Debugger;
import cpp.vm.Deque;
import cpp.vm.ExecutionTrace;
import cpp.vm.Gc;
import cpp.vm.Lock;
import cpp.vm.Mutex;
import cpp.vm.Profiler;
import cpp.vm.Thread;
import cpp.vm.Tls;
import cpp.vm.Unsafe;
import cpp.vm.WeakRef;

import cpp.zip.Compress;
import cpp.zip.Flush;
import cpp.zip.Uncompress;

import HXCPPRuntimeHello;

#if scriptable
import cpp.cppia.Host;
import cpp.cppia.HostClasses;

import HXCPPRuntimeCPPIA;
#end

@:build(HXCPPRuntimeBuild.configure())
class HXCPPRuntime {

    public static function main():Void {
        trace('HXCPP Runtime ready');
    }

}
