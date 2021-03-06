package net.wonderfl.editor.core 
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import net.wonderfl.editor.events.EditorEvent;
	import net.wonderfl.editor.ime.AbstractIMEClient;
	import net.wonderfl.editor.ime.IMEClient_10_0;
	import net.wonderfl.editor.ime.IMEClient_10_1;
	import net.wonderfl.editor.livecoding.LiveCoding;
	import net.wonderfl.editor.manager.ClipboardManager;
	import net.wonderfl.editor.manager.EditManager;
	import net.wonderfl.editor.manager.HistoryManager;
	import net.wonderfl.editor.manager.IKeyboadEventManager;
	import net.wonderfl.editor.manager.SelectionManager;
	import net.wonderfl.editor.operations.ReplaceText;
	import net.wonderfl.editor.operations.SetSelection;
	import net.wonderfl.utils.bind;
	import net.wonderfl.utils.versionTest;
	import net.wonderfl.editor.we_internal;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	[Event(name = 'undo', type = 'net.wonderfl.editor.events.EditorEvent')]
	[Event(name = 'redo', type = 'net.wonderfl.editor.events.EditorEvent')]
	public class UIFTETextInput extends UIFTETextField
	{
		private static var MATCH:Object = {
			')' : '(', ']' : '[', '」' : '「', '）' : '（', '｝' : '｛', '】' : '【', '〉' : '〈', '］': '［',
			'》' : '《', '』' : '『'
		}
		we_internal var _imeField:TextField;
		private var _historyManager:HistoryManager;
		private var _imeManager:AbstractIMEClient;
		private var _editManager:EditManager;
		private var _livecoding:LiveCoding;
		use namespace we_internal;

		public function UIFTETextInput() 
		{
			super();
			_editManager = new EditManager(this);
			_historyManager = new HistoryManager(this);  
			
			_imeField = new TextField;
			_imeField.height = boxHeight;
			_container.addChild(_imeField);
			_container.addChild(cursor);
			if (versionTest(10, 1)) {
				_imeField.type = TextFieldType.DYNAMIC;
				_imeManager = new IMEClient_10_1(this);
			} else {
				_imeField.type = TextFieldType.INPUT;
				_imeManager = new IMEClient_10_0(this);
			}
			
			addEventListener(Event.CUT, bind(_clipboardManager.cut));
			addEventListener(Event.PASTE, bind(_clipboardManager.paste));
			addEventListener(TextEvent.TEXT_INPUT, onInputText);
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			_livecoding = LiveCoding.getInstance();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, function ():void {
				if (stage.focus != _imeField && _imeManager.imeMode) {
					resetIMETFPosition();
					stage.focus = _imeField;
				}
			});
			stage.focus = this;
		}
		
		override protected function _replaceText(startIndex:int, endIndex:int, text:String):void
		{
			if (startIndex != endIndex || text.length > 0)
				_historyManager.pushReplaceOperation(startIndex, endIndex, text);
			
			if (LiveCoding.isLive && (startIndex != endIndex || text.length)) _livecoding.pushReplaceText(startIndex, endIndex, text);
				
			super._replaceText(startIndex, endIndex, text);
		}
		
		override public function set scrollY(value:int):void 
		{
			super.scrollY = value;
			
			if (LiveCoding.isLive) _livecoding.pushScrollV(value);
		}
		
		override public function set scrollH(value:int):void 
		{
			super.scrollH = value;
			
			if (LiveCoding.isLive) _livecoding.pushScrollH(value);
		}
		
		public function onSWFReloaded():void {
			if (LiveCoding.isLive) _livecoding.pushSWFReloaded();
		}
		
		override protected function onKeyDown(e:KeyboardEvent):void
		{
			_preventDefault = false;
			var c:String = String.fromCharCode(e.charCode);
			var k:int = e.keyCode;
			var i:int;
			if (c == 'z' && e.ctrlKey)
			{
				undo();
				dispatchChange();
				return;
			}
			else if (c == 'y' && e.ctrlKey)
			{
				redo();
				dispatchChange();
				return;
			}
			
			if (k == Keyboard.CONTROL || k == Keyboard.SHIFT || e.keyCode == 3/*ALT*/)
				return;
			
			var len:int = _plugins.length;
			for (i = 0; i < len; ++i) {
				if (_plugins[i].keyDownHandler(e)) {
					return;
				}
			}
			
			// to treat escape in some plug-ins
			if (e.keyCode == Keyboard.ESCAPE)
				return;
			
			_imeManager.keyDownHandler(e);
			
			if (_editManager.keyDownHandler(e)) {
				_preventDefault = true;
				dispatchChange();
				return;
			}
			
			_selectionManager.keyDownHandler(e);
		}
		
		private function dispatchChange():void
		{
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function undo():void {
			var stack:ReplaceText = _historyManager.undoStack;
			if (stack && LiveCoding.isLive) {
				_livecoding.pushReplaceText(stack.startIndex, stack.endIndex, stack.text);
			}
			
			_historyManager.undo();
			dispatchEvent(new EditorEvent(EditorEvent.UNDO));
		}
		
		public function redo():void {
			var stack:ReplaceText = _historyManager.redoStack;
			if (stack && LiveCoding.isLive) {
				_livecoding.pushReplaceText(stack.startIndex, stack.endIndex, stack.text);
			}
			
			
			_historyManager.redo();
			dispatchEvent(new EditorEvent(EditorEvent.REDO));
		}
		
		public function preventFollowingTextInput():void {
			_preventDefault = true;
		}
		
		protected function onInputText(e:TextEvent):void
		{
			if (_preventDefault) {
				return;
			}
			
			if (e.text.charCodeAt(0) < 0x20) return;
			
			if (e.text in MATCH) {
				findPreviousMatch(MATCH[e.text], e.text, _caret)
			}
			replaceSelection(e.text);
			setSelectionPromise = new SetSelection(_caret, _caret);
			_selectionManager.saveLastCol();
			checkScrollToCursor();
			dispatchChange();
			e.stopPropagation();
		}
		
		override public function _setSelection(beginIndex:int, endIndex:int, caret:Boolean = false):void 
		{
			super._setSelection(beginIndex, endIndex, caret);
			
			if (LiveCoding.isLive) _livecoding.pushCurrentSelection(beginIndex, endIndex);
			
		}
		
		override protected function drawComplete():Boolean 
		{
			resetIMETFPosition();
			
			return false;
		}
		
		public function resetIMETFPosition():void {
			if (_imeManager.imeMode) {
				var point:Point = getPointForIndex(_caret);
				_imeField.x = point.x - 2;
				_imeField.y = point.y - 2;
			}
		}
	}

}