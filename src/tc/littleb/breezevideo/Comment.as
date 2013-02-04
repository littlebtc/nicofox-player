package tc.littleb.breezevideo
{
	//import com.adobe.serialization.json.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	
	import mx.core.*;
				
	public class Comment extends UIComponent
	{
		[Event(name = "commentReady")]

		private var _commentFile:String;
		private var _commentDisplayNum:int = -1;
		private var _commentNum:int = 0;
		
		private var _commentRequest:URLRequest;
		private var _commentList:Array;
		private var _commentDisplayList:Array;
		private var _commentXML:XML;
		
		private var _firstCommentIndex:int = -1;
		private var _firstNakaCommentIndex:int = -1;
		private var _lastCommentIndex:int = -1;
		private var _lastNakaCommentIndex:int = -1;

		private var _ueSprite:CommentSprite;
		private var _shitaSprite:CommentSprite;
		private var _nakaSprite:CommentSprite;

		private var _uic:UIComponent;

		private var _fileReadCompleted: Boolean = false;
		/* Indicate whether we should stop updating comments */
		public var _freezed:Boolean;
		
		/* Mask sprite used to hide the CommentSprites */
		private var _nakaMask:Sprite;
		private var _shitaMask:Sprite;
		private var _ueMask:Sprite;

		/* Indicate the aspect ratio: true for 16:9 and false for 4:3 */
		private var _aspect16By9Mode:Boolean = true;		
		
		// private var is_kavideo:Boolean;
		
		public function Comment()
		{	
			_freezed = false;
			//myapp = app;

			_nakaSprite = new CommentSprite('naka');
			_shitaSprite = new CommentSprite('shita');
			_ueSprite = new CommentSprite('ue');
			
			_uic = new UIComponent();
			_nakaMask = new Sprite();
			_nakaMask = Sprite(_uic.addChild(_nakaMask));
			_ueMask = new Sprite();
			_ueMask = Sprite(_uic.addChild(_ueMask));
			_shitaMask = new Sprite();
			_shitaMask = Sprite(_uic.addChild(_shitaMask));
			generateMask();
			_ueSprite.mask = _ueMask;
			_shitaSprite.mask = _shitaMask;
			_nakaSprite.mask = _nakaMask;
			
			_uic.addChild(_ueSprite);
			_uic.addChild(_shitaSprite);
			_uic.addChild(_nakaSprite);
			//_nakaSprite.visible = false;
			this.addChild(_uic);
			//myapp.comment_container.addChild(uic);
			
		}
		/* Generate a mask for sprite */
		private function generateMask():void {
			for each (var mask:Sprite in [_nakaMask, _ueMask, _shitaMask]) {
				mask.graphics.clear();
				mask.graphics.beginFill(0xFF0000);
				if (_aspect16By9Mode) {
					mask.graphics.drawRect(0, 0, PlayerParams.PLAYER_WIDTH_16_BY_9, PlayerParams.PLAYER_HEIGHT);
				} else {
					/* For 4:3 mode, hide the extra part */
					var xOffset:Number = (PlayerParams.PLAYER_WIDTH_16_BY_9 - PlayerParams.PLAYER_WIDTH_4_BY_3) / 2;
					mask.graphics.drawRect(xOffset, 0, PlayerParams.PLAYER_WIDTH_4_BY_3, PlayerParams.PLAYER_HEIGHT);				
				}
				mask.graphics.endFill();
			}
		}
		private function _loadComment(url:String):void
		{
			_fileReadCompleted = false;
            // Check if we have no comment
            if (!url) {
            	_commentList = [];
				_commentDisplayList = [];
            	dispatchEvent(new Event('commentReady'));
				return;
            }
			
			var request:URLRequest = new URLRequest(url);
			var loader:URLLoader = new URLLoader(); 

			loader.addEventListener(Event.COMPLETE, goParse);
			loader.addEventListener(IOErrorEvent.IO_ERROR, _failRead);
			try {				
        loader.load(request);
      } catch (error:Error) {
        trace("Unable to load requested document.");
			  _failRead(new Event("LoaderError"));
      }
		}
		private function _failRead(e:Event):void {
			_commentList = [];
			_commentDisplayList = [];
			dispatchEvent(new Event('commentReady'));
		}

		private function goParse(e:Event):void
		{
			_commentXML = new XML();
			var loader2:URLLoader = URLLoader(e.target);
			_commentXML = XML(loader2.data);	 
			var video_id:String = _commentXML.view_counter.@id;
			var comment_id:String = _commentXML.thread.@thread;
			_commentList = new Array();
			var item:XML;
			var count:Number;
			//_commentNum = _commentXML.child('chat').length();
			for each (item in _commentXML.child('chat'))
			{
				/* Filter out deleted commment */
				if (item.@deleted == 1) {
					continue;
				}
				
				/* Process the comment list */
				var comment:Object =
				{
					anonymity: item.@anonymity,
					date: item.@date,					
					mail: item.@mail,
					no: item.@no,
					thread:item.@thread,
					user_id:item.@user_id,
					vpos:int(item.@vpos),
					text:item.toString(),
					pos:'', color: '', size:'', full: false
				};
				var mail:String=comment.mail;
				var pos_pattern:RegExp = 
				/(shita|ue|naka)/;
				var pos_match:Array = mail.match(pos_pattern);
				if (pos_match)
				{
					comment.pos= pos_match[1];
				}		
				else
				{
					comment.pos = 'naka';					
				}
						
				// Color match 1: color name; Color match 2: HTML hex code
				var color_pattern:RegExp = 
				/(white|red|pink|orange|yellow|green|cyan|blue|purple|niconicowhite|white2|truered|red2|passionorange|orange2|madyellow|yellow2|elementalgreen|green2|marineblue|blue2|nobleviolet|purple2|black|\#[0-9a-f]{6})/;
				var color_match:Array = mail.match(color_pattern);
				if (color_match)
				{
					comment.color = color_match[1];
				}		
				else
				{
					comment.color = 'white';					
				}
		

				var size_pattern:RegExp = 
				/(big|medium|small)/;
				var size_match:Array = mail.match(size_pattern);
				if (size_match)
				{
					comment.size = size_match[1];
				}		
				else
				{
					comment.size = 'meduim';					
				}
				var full_pattern:RegExp = /full/;
				if (mail.search(full_pattern) != -1) {
					comment.full = true;
				}
				
				_commentList.push(comment);
			}
			_commentList.sortOn(['no'], [Array.NUMERIC | Array.DESCENDING]);
			_commentNum = _commentList.length;
			_changeDisplayNum();
			_fileReadCompleted = true;
			dispatchEvent(new Event('commentReady'));
		}
		private function _changeDisplayNum():void {
			if (!_commentList || _commentList.length == 0) { return; }
			_freezed = true;
			if (_commentDisplayNum == 0) {
				_commentDisplayNum = _commentList.length;
			}
			
			_commentDisplayList = _commentList.concat();
			/* Sort the comment list and splice */
			if (_commentDisplayNum > 0)
			{
				_commentDisplayList = _commentDisplayList.slice(0, Math.min((_commentDisplayNum), (_commentDisplayList.length)));
				_commentDisplayList.sortOn(['no'], [Array.NUMERIC]);
				/* Sort the comment list. This CANNOT be done by: 
				_commentList.sortOn(['vpos'], [Array.NUMERIC])
				Because sortOn is NOT STABLE, so I have done a simple merge sort:
				*/			
				_commentDisplayList = merge_sort(_commentDisplayList);
			}
			
			_commentDisplayNum = _commentDisplayList.length;			
			_freezed = false;
		}

    public function prepareRereadComment():void {
      _fileReadCompleted = false;
    }

		/* After seeking, clear the old comment reading line */
		public function purgeIndex():void
		{
			_freezed = true;
			_firstCommentIndex = -1;
			_firstNakaCommentIndex = -1;
			_lastCommentIndex = -1;
			_lastNakaCommentIndex = -1;
			var comment:Object;
			for each(comment in _commentDisplayList)
			{			
				if (comment.object)
				{
					if (comment.pos == 'naka') _nakaSprite.recycleField(comment.object);
					else if (comment.pos == 'shita') _shitaSprite.recycleField(comment.object);
					else if (comment.pos == 'ue') _ueSprite.recycleField(comment.object);
					delete comment.object;
				}
			}		
			_freezed = false;
		}
		/* After timeupdate event by Video, update comments in a fixed interval */
		public function prepareComment(time:Number):void
		{
			var startTime:int = getTimer();
			var nowTime:int;
			
			
			//myapp.textArea.text = '+'+textfield_pool.usageCount+'+';
			//if (time % 1000 < 10)
			//{
				//textfield_pool.purge();
			//}
			if (this.visible==false)
			{return; }
			
			/* Check if freezed */
			if (_freezed) {
				return;
			}
			_nakaSprite.updateTime(time);
			var i: int = 0, k:int=0;
			var comment:Object, format:TextFormat;
			//myapp.textArea.text='';
			var lineMetrics:TextLineMetrics ;
			var scale:Number;
			var matrix:Matrix;
			var num:int = 0;
			var commentArea:Number = 0;
			if (!_commentDisplayList || _commentDisplayList.length == 0) { return; }
			
			commentArea = 0;
			/* Test if there are old comments to hide */
			while (_firstCommentIndex < _commentDisplayList.length) {
				/* When there is no element, skip */
				if (_firstCommentIndex < 0) {
					if (_lastCommentIndex < 0) { break; }
					else { _firstCommentIndex = 0; }
				}
				
				comment = _commentDisplayList[_firstCommentIndex];
				
				/* We reach the front */
				if (comment.vpos + PlayerParams.HIDE_COMMENT_OFFSET >= time)
				{
					break;
				}
				
				/* Test if the element is going to be removed */
				if (comment.object)
				{
					/* Avoid clearing processing data */
				   if ((comment.object as CommentTextField).comment_for != comment.no) {
				   		comment.object = null;
					
				   } else {
					if (comment.pos == 'shita') _shitaSprite.recycleField(comment.object);
					else if (comment.pos == 'ue') _ueSprite.recycleField(comment.object);
					if (comment.pos != 'naka') comment.object = null;
				   }
				
				}
				_firstCommentIndex++;
			}
			/* Test if there are old naka comments to hide */
			while (_firstNakaCommentIndex < _commentDisplayList.length) {
				/* When there is no element, skip */
				if (_firstNakaCommentIndex < 0) {
					if (_lastNakaCommentIndex < 0) { break; }
					else { _firstNakaCommentIndex = 0; }
				}
				
				comment = _commentDisplayList[_firstNakaCommentIndex];
				
				/* We reach the front */
				if (comment.vpos + PlayerParams.UNLOAD_NAKA_COMMENT_OFFSET >= time)
				{
					break;
				}
				
				/* Test if the element is going to be removed */
				if (comment.object)
				{
					/* Avoid clearing processing data */
				   if ((comment.object as CommentTextField).comment_for != comment.no) {
				   		comment.object = null;
					
				   } else if (comment.pos == 'naka') {
						_nakaSprite.recycleField(comment.object);
						comment.object = null;
				   }
				
				}
				_firstNakaCommentIndex++;
			}
			
			/* Test if there is new comments to load */
			while (_lastCommentIndex + 1 < _commentDisplayList.length) {
				nowTime = getTimer();
				if (commentArea > 512 * 384 || nowTime - startTime > 15) { break; }
				
				comment = _commentDisplayList[_lastCommentIndex + 1];
				/* We reach the front */
				if (comment.vpos + PlayerParams.SHOW_COMMENT_OFFSET > time) { break; }
				/* When we find elements that needs to load... */
				if (comment.vpos + PlayerParams.HIDE_COMMENT_OFFSET >= time)  {
					if (comment.pos == 'shita' && !comment.object) {
						comment.object = _shitaSprite.addComment(comment);
						commentArea += comment.object.width * comment.object.height;
					}
					if (comment.pos == 'ue' && !comment.object) {
						comment.object = _ueSprite.addComment(comment);
						commentArea += comment.object.width * comment.object.height;
					}				
				}
				_lastCommentIndex++;
			}
			
			commentArea = 0;

			/* Test if there is new naka comments to load */
			while (_lastNakaCommentIndex + 1 < _commentDisplayList.length)
			{
				nowTime = getTimer();
				if (commentArea > 512 * 384 / 3 || nowTime - startTime > 20) { break; }

				comment = _commentDisplayList[_lastNakaCommentIndex + 1];
				/* We reach the front */
				if (comment.vpos + PlayerParams.LOAD_NAKA_COMMENT_OFFSET > time) { break; }
				/* When we find elements that needs to load... */
				if (comment.vpos + PlayerParams.UNLOAD_NAKA_COMMENT_OFFSET >= time ) {
					if (comment.pos == 'naka' && !comment.object) {
						comment.object = _nakaSprite.addComment(comment);
						commentArea += comment.object.width * comment.object.height;
					}
				}
				_lastNakaCommentIndex++;
			}
	
		}
		
		private function _clearComment():void
		{
			this.purgeIndex();
			_commentDisplayList = new Array();
			
		}
		
		public function get commentFile():String {
			return _commentFile;
		}
		public function set commentFile(url:String):void {
			this._clearComment();
			this._loadComment(url);
			_commentFile = url;
		}

		public function get commentDisplayNum():int {
			return _commentDisplayNum;
		}
		public function set commentDisplayNum(number:int):void {			
			this._clearComment();			
			if (_fileReadCompleted) {
				_commentDisplayNum = number;
				_changeDisplayNum();
				dispatchEvent(new Event('commentReady'));
			} else {
				_commentDisplayNum = number;
				
			}
		}		

		public function get commentNum():int {
			return _commentNum;
		}
		private function yHitTest(y1:Number, height1:Number, y2:Number, height2:Number):Boolean
		{
			if (y1 <= y2)
			{ 
			return (y1 + height1 > y2);
			}			
			else
			{
			return (y2 + height2 > y1);
			}
		}

		public function get aspect16By9Mode():Boolean {
				return _aspect16By9Mode;
		}
		/* Setter that will be triggered by UI or BreezeVideo to toggle the 16:9 mode. */
		public function set aspect16By9Mode(mode:Boolean):void {
			_aspect16By9Mode = mode;
			generateMask();
		}
		
		private function merge_sort(A:Array):Array
		{			
			return merge_sort_inner(A, 0, A.length-1);	
		}
		private function merge_sort_inner(A:Array, p:int, r:int):Array
		{
			if (p < r)
			{
				var q:int = Math.floor((p+r) / 2);
				A = merge_sort_inner(A, p, q);
				A = merge_sort_inner(A, q+1, r);
				

				var left:Array = A.slice(p, q+1);
				var right:Array = A.slice(q+1, r+1);


				var i:int=0,j:int=0,k:int=p;
				while (left.length > 0 && right.length > 0)
				{ 
					if (left[i].vpos<=right[j].vpos)
					{												
						A[k] = left.shift();k++;
					}					
					else
					{
						A[k] = right.shift();k++;
					}
					
				}
				while (left.length > 0)
				{
					A[k] = left.shift(); k++;
				}
				while (right.length > 0)
				{
					A[k] = right.shift(); k++;
				}
				
			}
			return A;
		}

	}
}
