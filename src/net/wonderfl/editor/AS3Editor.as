package net.wonderfl.editor 
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDirection;
	import net.wonderfl.editor.core.UIFTETextInput;
	import net.wonderfl.editor.events.EditorEvent;
	import net.wonderfl.editor.ITextArea;
	import net.wonderfl.editor.core.LineNumberField;
	import net.wonderfl.component.core.UIComponent;
	import net.wonderfl.editor.core.UIFTETextField;
	import net.wonderfl.editor.error.ErrorMessage;
	import net.wonderfl.editor.manager.ClipboardManager;
	import net.wonderfl.editor.manager.CodeAssistManager;
	import net.wonderfl.editor.manager.EditorHotkeyManager;
	import net.wonderfl.editor.minibuilder.ASParserController;
	import net.wonderfl.editor.scroll.TextHScroll;
	import net.wonderfl.editor.scroll.TextVScroll;
	import net.wonderfl.utils.calcFontBox;
	import net.wonderfl.utils.listenOnce;
	import ro.minibuilder.main.editor.Location;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	public class AS3Editor extends UIComponent implements ITextArea, IEditor
	{
		private const CHECK_MOUSE_DURATION:int = 500;
		private var changeRevalIID:int;
		private var _field:UIFTETextInput;
		private var _codeAssistManager:CodeAssistManager;
		private var _editorHotkeyManager:EditorHotkeyManager;
		private var lineNums:LineNumberField;
		private var _vScroll:TextVScroll;
		private var _hScroll:TextHScroll;
		private var _boxWidth:int;
		private var _this:AS3Editor;
		private var _parser:ASParserController;
		private var _errorEngine:Sprite = new Sprite;
		private var _blackShade:Shape;
		
		public function AS3Editor() 
		{
			_this = this;
			_field = new UIFTETextInput;
			addChild(_field);
			
			
			_boxWidth = calcFontBox(_field.defaultTextFormat).width;
			
			
			addEventListener(FocusEvent.FOCUS_IN, function(e:FocusEvent):void {
				stage.focus = _field;
			});
			
			addEventListener(FocusEvent.KEY_FOCUS_CHANGE, function(e:Event):void {
				e.preventDefault();	
			});
			
			_field.addEventListener(Event.RESIZE, onFieldResize);
			_field.addEventListener(EditorEvent.UNDO, hideCodeAssists);
			_field.addEventListener(EditorEvent.REDO, hideCodeAssists);
			_field.addEventListener(ScrollEvent.SCROLL, onScroll);
			
			lineNums = new LineNumberField(_field);
			addChild(lineNums);
			lineNums.addEventListener(Event.RESIZE, function ():void {
				_field.x = lineNums.width;
				_field.width = _width - lineNums.width;
			});
			
			_vScroll = new TextVScroll(_field);
			_hScroll = new TextHScroll(_field);
			_hScroll.addEventListener(Event.CHANGE, onHScroll);
			_vScroll.addEventListener(Event.CHANGE, onVScroll);
			
			_blackShade = new Shape;
			_blackShade.graphics.beginFill(0);
			_blackShade.graphics.drawRect(0, 0, _vScroll.width, _hScroll.height);
			_blackShade.graphics.endFill();
			
			addChild(_blackShade);
			addChild(_vScroll);
			addChild(_hScroll);
			
			listenOnce(this, Event.ADDED_TO_STAGE, init);
		}
		
		private function onVScroll(e:Event):void 
		{
			_field.setScrollYByBar(_vScroll.value);
		}
		
		private function onScroll(e:ScrollEvent):void 
		{
			if (e.direction == ScrollEventDirection.VERTICAL) {
				_vScroll.value = e.position;
			} else { // horizontal
				_hScroll.value = e.position;
			}
			
			redrawBars();
		}
		
		public function hideCodeAssists(e:EditorEvent):void 
		{
			_codeAssistManager.cancelAssist();
		}
		
		private function init():void {
			_parser = new ASParserController(stage, _this);
			_parser.addEventListener(Event.COMPLETE, dispatchEvent);
			_codeAssistManager = new CodeAssistManager(_field, _parser, stage, onComplete);
			_editorHotkeyManager = new EditorHotkeyManager(_field, _parser);
			_field.addPlugIn(_codeAssistManager);
			_field.addPlugIn(_editorHotkeyManager);
			_field.addEventListener(Event.CHANGE, onChange);
		}
		
		private function onComplete():void
		{
		}
		
		private function onChange(e:Event):void
		{
			if (triggerAssist())
				_codeAssistManager.triggerAssist();
			else
				_parser.sourceChanged(text, '');
				
			lineNums.draw();
			_field.clearErrorMessages();
			
			trace("AS3Editor.onChange > e : " + e + " [_vScroll]" + _vScroll + " " + <> maxScroll : { _field.maxScrollV }, scrollY : { _field.scrollY}, scroll : {scroll}</>);
			
			var value:int;
			if (_field.maxScrollV < _vScroll.max) {
				trace('in if');
				var scroll:int = Math.min(_field.scrollY, _vScroll.max);
				_vScroll.setThumbPercent(_field.visibleRows / (_field.visibleRows + _field.maxScrollV));
				_vScroll.setSliderParams(0, _field.maxScrollV, scroll);
				_field.setScrollYByBar(scroll);
			}
		}
		
		private function redrawBars():void {
			_hScroll.setThumbPercent((_width - lineNums.width - 15) / _field.maxWidth);
			
			var maxH:int = ((_field.maxWidth - _width + lineNums.width + 15) / _field.boxWidth) >> 0;
			maxH = (maxH < 0) ? 0 : maxH;
			maxH++;
			
			// update position
			_hScroll.setSliderParams(0, maxH, _hScroll.value);
			
			_vScroll.setThumbPercent(_field.visibleRows / (_field.visibleRows + _field.maxScrollV));
			_vScroll.setSliderParams(0, _field.maxScrollV, _field.scrollY);
		}
		
		private function onFieldResize(e:Event):void 
		{
			redrawBars();
		}
		
		private function onHScroll(e:Event):void 
		{
			_field.scrollH = _hScroll.value;
		}
		
		private function onTextScroll(e:Event):void 
		{
		}
		
		override protected function updateSize():void 
		{
			//_liveCodingController.width = _width - _vScroll.width;
			_field.setSize(_width - lineNums.width - _vScroll.width, _height - _hScroll.height - 20); 
			_field.y = 20;
			_vScroll.height = _height - 20 - _hScroll.height;
			_hScroll.width = _width - _vScroll.width;
			_vScroll.x = _width - _vScroll.width;
			_vScroll.y = 20;
			_hScroll.y = _field.height + 20;
			_blackShade.x = _vScroll.x;
			_blackShade.y = _hScroll.y;
			lineNums.height = _field.height;
			lineNums.y = 20;
		}
		
		public function clearErrors():void {
			_field.clearErrorMessages();
			startDrawingErrors();
		}
		
		public function setFontSize($size:int):void {
			
		}
		
		public function onSWFReloaded():void {
			_field.onSWFReloaded();
		}
		
		public function setError($row:int, $col:int, $message:String):void {
			_field.addErrorMessage(new ErrorMessage([$row, $col, $message]));
			startDrawingErrors();
		}
		
		private function startDrawingErrors():void {
			if (!_errorEngine.hasEventListener(Event.ENTER_FRAME))
				_errorEngine.addEventListener(Event.ENTER_FRAME, drawError);
		}
		
		private function drawError(e:Event):void 
		{
			_errorEngine.removeEventListener(Event.ENTER_FRAME, drawError);
			_field.applyFormatRuns();
		}
		
		protected function triggerAssist():Boolean
		{
			// refactor
			var str:String = text.substring(Math.max(0, _field.caretIndex-30), _field.caretIndex);
			str = str.split('').reverse().join('');
			return (/^(?:\(|\:|\.|\ssa\b|\swen\b|\ssdnetxe)/.test(str))
		}
		
		public function findDefinition():Location
		{
			return _parser.findDefinition(_field.caretIndex);
		}
		
		public function copy():void {
			ClipboardManager.getInstance().copy();
		}
		
		public function selectAll():void {
			_field.onSelectAll(null);
		}
		
		public function applyFormatRuns():void
		{
			_field.applyFormatRuns();
		}
		
		public function addFormatRun(beginIndex:int, endIndex:int, bold:Boolean, italic:Boolean, color:String):void
		{
			_field.addFormatRun(beginIndex, endIndex, bold, italic, color);
		}
		
		public function set scrollY(value:int):void {
			_field.scrollY = value;
		}
		
		public function set scrollH(value:int):void {
			
		}
		
		public function get selectionBeginIndex():int { return _field.selectionBeginIndex; }
		public function get selectionEndIndex():int { return _field.selectionEndIndex; }
		
		public function clearFormatRuns():void
		{
			_field.clearFormatRuns();
		}
		
		public function setSelection($selectionBeginIndex:int, $selectionEndIndex:int):void {
			_field.setSelection($selectionBeginIndex, $selectionEndIndex);
		}
		
		/* INTERFACE net.wonderfl.editor.IEditor */
		
		public function paste():void
		{
			ClipboardManager.getInstance().paste();
		}
		
		public function cut():void
		{
			ClipboardManager.getInstance().cut();
		}
		
		public function saveCode():void
		{
			_editorHotkeyManager.saveCode();
		}
		
		public function get text():String {
			return _field.text.replace(/\r/gm, "\n").replace(/\t/g, "    ");
		}
		
		public function set text(value:String):void {
			_field.text = value;
			onChange(null);
		}
		
	}
}