package net.wonderfl.editor.scroll 
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import net.wonderfl.editor.core.FTETextField;
	import net.wonderfl.editor.core.UIComponent;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	[Event(name = "scroll", type = "flash.events.Event")]
	public class TextScrollBar extends UIComponent
	{
		protected var _target:FTETextField;
		protected var _handle:TextScrollBarHandle;
		protected var _prevMouse:int;
		protected var _diff:Number;
		protected var _handleMax:int;
		protected var _value:int = -1;
		protected var _min:int;
		protected var _max:int;
		
		public function TextScrollBar($target:FTETextField) 
		{
			_target = $target;
			_target.addEventListener(Event.SCROLL, onTargetScroll);
			
			_handle = new TextScrollBarHandle;
			_handle.addEventListener(MouseEvent.MOUSE_DOWN, _onDrag);
			addChild(_handle);
			
			addEventListener(MouseEvent.MOUSE_OVER, function ():void {
				Mouse.cursor = MouseCursor.BUTTON;
			});
			addEventListener(MouseEvent.MOUSE_OUT, function ():void {
				Mouse.cursor = MouseCursor.IBEAM;
			});
			addEventListener(MouseEvent.MOUSE_UP, _onTrackMouseUp);
		}
		
		private function _onTrackMouseUp(e:MouseEvent):void 
		{
			onTrackMouseUp(e);
		}
		
		protected function calcValueFromHandlePos($position:Number):void {
			var newValue:int = _min + (_max - _min) * $position / _handleMax;
			
			if (newValue != _value) {
				_value = newValue;
				dispatchEvent(new Event(Event.SCROLL));
			}
		}
		
		protected function truncateHandlePos($pos:Number):Number {
			$pos = ($pos < 0) ? 0 : $pos;
			$pos = ($pos > _handleMax) ? _handleMax : $pos;
			
			return $pos;
		}
		
		private function _onDrag(e:MouseEvent):void 
		{
			onDrag(e);
			stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
			stage.addEventListener(Event.ENTER_FRAME, checkMouse);
		}
		
		private function onDrop(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
			stage.removeEventListener(Event.ENTER_FRAME, checkMouse);
		}
		
		public function setSliderParams($min:int, $max:int, $value:int):void {
			_min = $min;
			_max = $max;
			_value = $value;
		}
		
		protected function checkMouse(e:Event):void { }
		protected function onDrag(e:MouseEvent):void { }
		protected function onTargetScroll(e:Event):void { }
		protected function onTrackMouseUp(e:MouseEvent):void { }
		public function setThumbPercent(value:Number):void { }		
		public function set pageSize(value:int):void { }
		public function get value():int { return _value; }
	}

}