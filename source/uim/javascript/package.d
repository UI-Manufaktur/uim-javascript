﻿module uim.javascript;

// Libraries
public import uim.core;
public import uim.oop;

// Modules
public import uim.javascript.base;
public import uim.javascript.helper;
public import uim.javascript.array;
public import uim.javascript.js;
public import uim.javascript.command;
public import uim.javascript.obj;
public import uim.javascript.module_;

@safe:
class DJSRoot {
	this() {}

	override string toString() { return ""; }
}

string jsArray() { return "[]"; }
string jsArray(string[] values) { return "["~values.join(",")~"]"; }
unittest {
	assert(jsArray() == "[]");
	assert(jsArray(["a", "b"]) == "[a,b]");
}

string jsObject(string[string] values, bool sorted = true) {
	string[] props;
	foreach(k; values.getKeys(sorted)) props ~= k~":"~values[k];
	return "{"~props.join(",")~"}"; }
unittest {
	assert(jsObject(["a":"1", "b":"2"]) == "{a:1,b:2}");
}

string jsBlock(DJS content) { return jsBlock(content.toString); }
string jsBlock() { return "{}"; }
string jsBlock(string content) { return "{"~content~"}"; }
unittest {
	assert(jsBlock() == "{}");
	assert(jsBlock("return;") == "{return;}");
}

string jsFCall(string name = "") { return "%s()".format(name); } 
string jsFCall(string name, string[] parameters) { return "%s(%s)".format(name, parameters.join(",")); } 
unittest {
	assert(jsFCall("fn") == "fn()");
	assert(jsFCall("fn", ["a", "b"]) == "fn(a,b)");
}

string jsOCall(string name = "") { return ".%s()".format(name); } 
string jsOCall(string name, string[] parameters) { return ".%s(%s)".format(name, parameters.join(",")); } 
unittest {
	assert(jsOCall("fn") == ".fn()");
	assert(jsOCall("fn", ["a", "b"]) == ".fn(a,b)");
}

// Building javascript functions
string jsFunc(DJS content) { return jsFunc(content.toString); } 
string jsFunc(string[] parameters, DJS content) { return jsFunc(parameters, content.toString);  } 
string jsFunc(string name, string[] parameters, DJS content) { return jsFunc(name, parameters, content.toString);  } 

string jsFunc(string content) { return "function()%s".format(jsBlock(content)); } 
string jsFunc(string[] parameters, string content) { return "function(%s)%s".format(parameters.join(","), jsBlock(content)); } 
string jsFunc(string name, string content) { return "function %s()%s".format(name, jsBlock(content)); } 
string jsFunc(string name, string[] parameters, string content) { return "function %s(%s)%s".format(name, parameters.join(","), jsBlock(content)); } 
unittest {
	assert(jsFunc("return;") == "function(){return;}");
	assert(jsFunc(["a", "b", "c"], "return;") == "function(a,b,c){return;}");
	assert(jsFunc("fn", ["a", "b", "c"], "return;") == "function fn(a,b,c){return;}");
}

unittest {
	auto js = JS.If("x > 0", "do something;");
	assert(JS.Func() == "function(){}");

	assert(JS.Switch("value", ["1": "do something;"]) == "switch(value){case 1: do something; break;}"); 
	assert(JS.Switch("value", ["1": "do something;"], "do the rest;") == "switch(value){case 1: do something; break;default: do the rest;}"); 
		
	assert(JS.Constructor("variable", "content") == "constructor(variable){content}");
	assert(JS.Get("name", "content") == "get name(){content}");
	assert(JS.Set("name", ["A", "B"], "content") == "set name(A, B){content}");
}

auto jsIf(string condition, string content) { return "if (%s) { %s }".format(condition, content); }
auto jsElse(string content) { return "else { %s }".format(content); }
auto jsIfElse(string condition, string ifContent, string elseContent) { 
	return jsIf(condition, ifContent)~jsElse(elseContent); }

auto jsThen(string code) { return ".then(function (response) { %s })".format(code); }
auto jsCatch(string code) { return ".catch(function (error) { %s })".format(code); }

auto jsImports(string[string] imports) {
	string result;
	foreach(k,v; imports) if (v) result~=`import %s from "%s";`.format(v, k); else `import "%s";`.format(k);
	return result;
} 

auto jsForIn(string item, string items, string content) { return "for(let %s in %s) { %s }".format(item, items, content); }
auto jsForOf(string item, string items, string content) { return "for(let %s ofs %s) { %s }".format(item, items, content); }

auto jsClass(string name, string[] fields, string[] methods) {
	string setFields;
	foreach(field; fields) setFields ~= "this.%s=%s;".format(field, field);
	return "class %s{constructor(%s){%s}%s}".format(name, fields.join(","), setFields, methods.join(""));
}
auto jsClass(string name, string[] fields, string methods = null) {
	string setFields;
	foreach(field; fields) setFields ~= "this.%s=%s;".format(field, field);
	return "class %s{constructor(%s){%s}%s}".format(name, fields.join(","), setFields, methods);
}
unittest {
	/// TODO
}

auto jsClassExtends(string superName, string name, string[] superFields, string[] newFields, string[] methods) {
	string setFields;
	foreach(field; newFields) setFields ~= "this.%s=%s;".format(field, field);
	return "class %s extends %s{constructor(%s){super(%);%s}%s}".format(name, superName, superFields.join(","), (superFields~newFields).join(","), setFields, methods.join(""));
}
auto jsClassExtends(string superName, string name, string[] superFields, string[] newFields, string methods = null) {
	string setFields;
	foreach(field; newFields) setFields ~= "this.%s=%s;".format(field, field);
	return "class %s extends %s{constructor(%s){super(%s);%s}%s}".format(name, superName, superFields.join(","), (superFields~newFields).join(","), setFields, methods);
}
unittest {
	/// TODO
}

auto jsWhile(string[] conditions, string content) { return jsWhile(jsAnd(conditions), content); }
auto jsWhile(string condition, string content) { return "while%s%s".format(condition, jsBlock(content)); }
unittest {
	assert(jsWhile(["(a>b)", "(b<10)"], "b++;") == "while((a>b)&&(b<10)){b++;}");
	assert(jsWhile("(a>b)", "b++;") == "while(a>b){b++;}");
}

auto jsConst(string[string] settings) { 
	string result;
	foreach(k, v; settings) result ~= jsConst(k, v);
	return result;	
 }
auto jsConst(string name, string setting) { return "const %s=%s;".format(name, setting); }
unittest {
	///
}

auto jsLet(string[string] settings) { 
	string result;
	foreach(k, v; settings) result ~= jsLet(k, v);
	return result;	
 }
auto jsLet(string name, string setting = null) { 
	if (setting) return "let %s=%s;".format(name, setting); 
	return "let %s;".format(name); }
unittest {
	///
}

auto jsForEach(string arrayName, string[] params, string content) {
	return "%s.forEach(%s);".format(arrayName, jsFunc(params, content));
}
auto jsForEach(string arrayName, string content) {
	return "%s.forEach(%s);".format(arrayName, jsFunc(["element"], content));
}
unittest {
	///
}

auto jsCreateElement(string tag) {
	return "document.createElement('"~tag~"')";
}
unittest {
}

auto jsCreateElement(string target, string tag, string text = null) {
	string result;
	result ~= jsLet(target, jsCreateElement(tag));
	if (target) {
		if (text.length > 0) result ~= `var node=document.createTextNode('`~text.replace("'", "\\'")~`');`; 
		if (text.length > 0) result ~= target~`.appendChild(node);`;
		return  result;
	}
	return jsCreateElement(tag);
}
unittest {
	assert(jsCreateElement("a", "b") == "let a=document.createElement('b');");
//	assert(jsCreateElement(null, "b") == "document.createElement('b');");
}

auto jsCreateElement(string target, string tag, string[string] attributes, string text = null) {
	string results = jsCreateElement(target, tag, text);
	if (target) {
		foreach(k, v; attributes) results ~= "%s.setAttribute('%s','%s');".format(target, k, v);
	}
	return results;
}
unittest {
	assert(jsCreateElement("a", "b", ["c":"d"]) == "let a=document.createElement('b');a.setAttribute('c','d');");
}

auto jsCreateElement(string target, string tag, string[] classes, string text = null) {
	string results = jsCreateElement(target, tag, text);
	if (target) {
	foreach(c; classes) results ~= "%s.classList.add('%s');".format(target, c);
	}
	return results;
}
unittest {
	assert(jsCreateElement("a", "b", ["c":"d"]) == "let a=document.createElement('b');a.setAttribute('c','d');");
}

auto jsCreateElement(string target, string tag, string[] classes, string[string] attributes, string text = null) {
	string results = jsCreateElement(target, tag, text);
	if (target) {
		foreach(c; classes) results ~= "%s.classList.add('%s');".format(target, c);
		foreach(k, v; attributes) results ~= "%s.setAttribute('%s','%s');".format(target, k, v);
	}
	return results;
}
unittest {
	assert(jsCreateElement("a", "b", ["c":"d"]) == "let a=document.createElement('b');a.setAttribute('c','d');");
}

auto jsAppendChilds(string target, string[] childs...) {
	string results;
	foreach(c; childs) results ~= "%s.appendChild(%s);".format(target, c);
	return results;
}
unittest {
	writeln(jsAppendChilds("a", "b"));
	assert(jsAppendChilds("a", "b") == "a.appendChild(b);");
}

auto defineCustomElements(string[string] elements) {
	string results;
	foreach(k, v; elements) results ~= defineCustomElements(k, v);
	return results;
}
auto defineCustomElements(string tag, string className) {
	return "customElements.define('%s', %s);".format(tag, className);
}

auto jsElementById(string id) {
	return `document.getElementById("%s");`.format(id);
}
auto jsElementById(string target, string id) {
	return `%s=document.getElementById("%s");`.format(target, id);
}

auto jsFetch(string url, string[] thens = null) {
	string result = "fetch('%s')".format(url);
	foreach(t; thens) result ~= ".then(%s)".format(t);
	return result~";";
} 
unittest {
	assert(jsFetch("/abc/dec") == "fetch('/abc/dec');");
}

auto jsFetch(string url, string[string] options, string[] thens) {
	string result = "fetch('%s', %s)".format(url, toJS(options));
	foreach(t; thens) result ~= ".then(%s)".format(t);
	return result~";";
} 
unittest {
	
}
