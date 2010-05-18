package net.wonderfl.editor.scroll 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import net.wonderfl.editor.core.FTETextField;
	import net.wonderfl.editor.core.UIComponent;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	public class TextVScroll extends UIComponent
	{
		private static const MINIMUM_THUMB_HEIGHT:int = 15;
		private var _handle:TextScrollBarHandle;
		private var _target:FTETextField;
		private var _scrollY:int = -1;
		private var _trackHeight:int;
		private var _prevMouseY:int;
		private var _diff:Number;
		
		public function TextVScroll($target:FTETextField) 
		{
			_width = 15;
			_handle = new TextScrollBarHandle;
			_handle.addEventListener(MouseEvent.MOUSE_DOWN, onDrag);
			
			_target = $target;
			_target.addEventListener(Event.SCROLL, onScroll);
			
			addChild(_handle);
			addEventListener(MouseEvent.MOUSE_UP, onTrackClick);
			addEventListener(MouseEvent.MOUSE_OVER, function ():void {
				Mouse.cursor = MouseCursor.BUTTON;
			});
			addEventListener(MouseEvent.MOUSE_OUT, function ():void {
				Mouse.cursor = MouseCursor.IBEAM;
			});
		}
		
		private function onTrackClick(e:MouseEvent):void 
		{
			updateHandlePos(mouseY);
		}
		
		private function onScroll(e:Event):void 
		{
			_handle.y = _trackHeight * _target.scrollY / _target.maxScrollV;
		}
		
		protected function onDrag(event:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
			//stage.addEventListener(MouseEvent.MOUSE_MOVE, onSlide);
			stage.addEventListener(Event.ENTER_FRAME, checkMouse);
			_prevMouseY = NaN;
			_diff = _handle.y - mouseY;
		}
		
		private function updateHandlePos($ypos:int):void {
			_handle.y = truncate(_diff + $ypos);
			var oldValue:int = _scrollY;
			_scrollY = Math.round(_target.maxScrollV * (_handle.y / _trackHeight));
			if (oldValue != _scrollY) {
				_target.scrollY = _scrollY;
			}
		}
		
		private function checkMouse(e:Event):void 
		{
			if (mouseY != _prevMouseY) {
				updateHandlePos(_prevMouseY = mouseY);
			}
		}
		
		private function truncate($value:int):int {
			$value = ($value < 0) ? 0 : $value;
			$value = ($value > _trackHeight) ? _trackHeight : $value;
			
			return $value;
		}
		
		protected function onDrop(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
			//stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSlide);
			stage.removeEventListener(Event.ENTER_FRAME, checkMouse);
			_handle.stopDrag();
		}
		
		//protected function onSlide(event:MouseEvent):void
		//{
			//var oldValue:int = _scrollY;
			//_scrollY = Math.ceil(_target.maxScrollV * (_handle.y / _trackHeight));
			//if (oldValue != _scrollY) {
				//_target.scrollY = _scrollY;
			//}
		//}
		
		override public function set width(value:Number):void {}
		
		override protected function updateSize():void {
			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
			
			graphics.beginFill(0x111111);
			graphics.drawRect(0, 0, _width, _height - MINIMUM_THUMB_HEIGHT);
			graphics.endFill();
			
			updateThumb();
		}
		
		private function updateThumb():void {
			var h:int;
			h = _height * _target.visibleRows / _target.maxScrollV;
			
			if (h >= _height)
				_handle.visible = false;
			
			h = (h < MINIMUM_THUMB_HEIGHT) ? MINIMUM_THUMB_HEIGHT : h;
			_trackHeight = _height - h - MINIMUM_THUMB_HEIGHT;
			
			_handle.setSize(_width, h);
		}
	}
}

