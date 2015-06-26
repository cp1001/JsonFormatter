package
{
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * 2015.6.25
	 * 拖入文件或文件夹，对所有文件读取文本，并格式化为带格式的文本存回源文件，以便于阅读。
	 * @author chenpeng
	 * 
	 */	
	[SWF(width="400",height="300",backgroundColor="0x333333")]
	public class JsonFormatter extends Sprite
	{
		private var list:Array = [];
		private var curHandleFileIndex:int = 0;
		
		private var txt:TextField;
		
		public function JsonFormatter()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		protected function onAddedToStage(event:Event):void
		{
			// TODO Auto-generated method stub
			txt = new TextField();
			this.addChild(txt);
			var tf:TextFormat = new TextFormat();
			tf.size = 24;
			tf.bold = true;
			tf.align = TextFormatAlign.CENTER;
			txt.defaultTextFormat = tf;
			txt.text = "\n\n\nDrap Diles Here";
			txt.selectable = false;
			txt.width = 400;
			txt.height = 300;
			txt.textColor = 0x999999;
			txt.mouseEnabled = true;
			
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, nativeDragEnterHandler);
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,nativeDragDropHandler);
		}
		
		private function nativeDragEnterHandler(event:NativeDragEvent):void
		{
			if(event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{  
				NativeDragManager.acceptDragDrop(this);
			}
		}
		
		private function nativeDragDropHandler(event:NativeDragEvent):void
		{
			// TODO Auto-generated method stub
			list = [];
			curHandleFileIndex = 0;
			var arr:Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			for each(var file:File in arr)
			{
				if(file.isDirectory)
				{
					list = list.concat(FileUtil.search(file.nativePath));
				}
				else
				{
					list.push(file);
				}
			}
			handleNextFile();
		}
		
		private function handleNextFile():void
		{
			trace("handleNextFile");
			if(curHandleFileIndex >= this.list.length)
			{
				return;
			}
			var file:File = this.list[curHandleFileIndex++];
			handleFile(file);
		}
		
		private function handleFile(file:File):void
		{
			var obj:Object = {};
			var content:String = FileReadUTF8(file.url);
			try
			{
				obj = JSON.parse(content);
			}
			catch(e:Error)
			{
				trace(e);
				return;
			}
			content = JSON.stringify(obj, null, "\t");
			FileWriteUTF8(file.url, content, FileMode.WRITE);
			handleNextFile();
		}
		
		/**
		 * 保存数据到指定文件，返回是否保存成功
		 * @param path 文件完整路径名
		 * @param data 要保存的数据
		 * @param deleteExist 是否先删除已经存在的文件
		 * @param charSet 写入时使用的字符串编码方式,默认utf-8
		 */		
		public static function FileWriteUTF8(path:String, content:String, mode:String = FileMode.APPEND):Boolean
		{
			path = FileUtil.escapePath(path);
			var file:File = File.applicationDirectory.resolvePath(path);
			if(file.isDirectory)
			{
				return false;
			}
			var fs:FileStream = new FileStream();
			try
			{
				fs.open(file,mode);
				if(mode == FileMode.APPEND)
				{
					content = "\n" + content;
				}
				//var reg:RegExp = /\r/g;
				var reg:RegExp = new RegExp("\\r", "g");
				content = content.replace(reg, "\n");
				fs.writeUTFBytes(content);
			}
			catch(e:Error)
			{
				fs.close();
				return false;
			}
			fs.close();
			return true;
		}
		/**
		 * 
		 * @param path 文件完整路径名
		 * @return 
		 * 
		 */		
		public static function FileReadUTF8(path:String):String
		{
			var content:String = "";
			path = FileUtil.escapePath(path);
			var file:File = File.applicationDirectory.resolvePath(path);
			if(file.isDirectory)
			{
				return "";
			}
			var fs:FileStream = new FileStream();
			try
			{
				fs.open(file, FileMode.READ);
				fs.position = 0;
				content = fs.readUTFBytes(fs.bytesAvailable);
			}
			catch(e:Error)
			{
				fs.close();
				return "";
			}
			fs.close();
			return content;
		}
	}		
}
