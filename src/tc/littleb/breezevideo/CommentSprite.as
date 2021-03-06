package tc.littleb.breezevideo
{
	import flash.display.*;
	import flash.text.*;
	import flash.utils.*;
	
	public class CommentSprite extends Sprite
	{
		private var time:Number;
		private var comment_type:String;
		private const comment_max:int = 50;
		private var _nakaInitXOffset:int;
		
		//private var comment_pool:Array;
		
		public function CommentSprite(new_type:String)
		{
			super();
			if (new_type != 'shita' && new_type != 'ue' && new_type != 'naka') {
				throw new Error('CommentSprite: Unreconized Type.');
				return false;				
			}

			/* Calculate the init X offset for "naka" comments,
			 * where comments should be placed 1sec before the commment position.
			 * | 16:9 Range           |
			 * |    | 4:3 Range |     |
			 *                  ^ 
			 *                  ^----------nakaInitXOffset
			 * */
			_nakaInitXOffset = PlayerParams.PLAYER_WIDTH_4_BY_3 + (PlayerParams.PLAYER_WIDTH_16_BY_9 - PlayerParams.PLAYER_WIDTH_4_BY_3) / 2;
			 
			this.comment_type = new_type;
			//this.cacheAsBitmap = true;
			//nico_bevel_black = nico_bevel.clone();
			//nico_bevel_black.highlightColor = 0xFFFFFF;	
		    var i:int, j:int;
			for (i = 0; i < comment_max; i++) {
			  var tf:CommentTextField = new CommentTextField(new_type);
			  tf.visible = false;
			  this.addChild(tf);
			}			
			if (new_type == 'naka') {
			  setInterval(this.updateNakaPosition, 20);
			}
		}
		
		public function addComment(info:Object):DisplayObject
		{
			var use_object:DisplayObject;
			var hit_objects:Array = new Array();
			/* If the pool is not full */
			if (this.numChildren < comment_max) {
				var tf:CommentTextField = new CommentTextField(this.comment_type);
				tf.visible = false;			  
				use_object = this.addChild(tf);
			} else {
			/* Hey, we have a full pool! */
				var last_field:CommentTextField = this.getChildAt(this.numChildren - 1) as CommentTextField;
						
				if (last_field.comment_for != -1) {
								
					/* Ouch, our container is full */
					/* Move the first item to the last */
					(this.getChildAt(0) as CommentTextField).resetFormat();
					this.setChildIndex(this.getChildAt(0), this.numChildren - 1);                
					use_object = this.getChildAt(this.numChildren - 1);
					
					/* Still prepare for hittest */
					for (i = 0; i < this.numChildren - 1; i++) {
						var tmp_object:DisplayObject = this.getChildAt(i);
						hit_objects.push({x: tmp_object.x, y: tmp_object.y, width: tmp_object.width, height: tmp_object.height});
					}
					
				} else {
					/* Find out last available object */
					var i:int;
				
					for (i = 0; i < this.numChildren; i++) {
						/* Find the last availble one */
						use_object = this.getChildAt(i);
						if ((use_object as CommentTextField).comment_for == -1) {							
							break;
						} else {
							hit_objects.push({x: use_object.x, y: use_object.y, width: use_object.width, height: use_object.height});
						}
					}
				}
			}
			
			/* Set some necessary variable */
			var use_field:CommentTextField = use_object as CommentTextField;
			use_field.comment_for = info.no;
			clearInterval(use_field.interval_id);			
			use_field.x = PlayerParams.PLAYER_WIDTH_16_BY_9;
			if (this.comment_type == 'shita') {
				use_field.y = PlayerParams.PLAYER_HEIGHT;
			} else {
				use_field.y = 0;
			}
			use_field.text = info.text;
			use_field.vpos = info.vpos;
			use_field.formatSelect(info.size, info.color);
			use_field.visible = true;
						
			if (this.comment_type == 'naka') {
					/* Set a interval for naka marquee */
					//use_field.interval_id = setInterval(updateNakaPosition, 50, use_object);
			} else {
					/* Scaling for non-naka */
					
					/* Determine the "Resize base width". 
					 * If "full" command is used, base will be PlayerParams.PLAYER_WIDTH_16_BY_9.
					 * otherwise PlayerParams.PLAYER_WIDTH_4_BY_3 will be used. */
					var resizeBase:int = PlayerParams.PLAYER_WIDTH_4_BY_3 - PlayerParams.PLAYER_HORIZONTAL_MARGIN * 2;
					if (info.full) {
						resizeBase = PlayerParams.PLAYER_WIDTH_16_BY_9 - PlayerParams.PLAYER_HORIZONTAL_MARGIN * 2;
					}
					
					var scale:Number = 1.0;
					
					if (use_field.height * 3 > PlayerParams.PLAYER_HEIGHT)
					{
						use_field.scaleY = 0.5;
						use_field.scaleX = 0.5;
					}
					if (use_field.width > resizeBase)
					{							
						scale = resizeBase / use_field.width;
						use_field.scaleY = scale;
						use_field.scaleX = scale;		
					}
					/* Place the comment to the center of the sprite. */
					use_field.x = (PlayerParams.PLAYER_WIDTH_16_BY_9 - use_field.width) / 2.00;
					if (this.comment_type == 'shita') {
						use_field.y = PlayerParams.PLAYER_HEIGHT - use_field.height;
					}
			}
			var plus_height_self:int = 0;
			var plus_height_other:int = 0;
			/* Prepare hittest */		
			if (this.comment_type == 'shita') {
				hit_objects.sortOn('y', Array.NUMERIC|Array.DESCENDING);
				plus_height_self = -1;
				use_object.y = PlayerParams.PLAYER_HEIGHT - use_object.height;
			} else {
				hit_objects.sortOn('y', Array.NUMERIC);
				plus_height_other = 1;
			}
			var hit_object:Object;
			/* Take a hittest */
					for each(hit_object in hit_objects)
					{
																				
						var future_x:Number = hit_object.x +
						(PlayerParams.PLAYER_WIDTH_4_BY_3 + hit_object.width) * (this.time - use_field.vpos - 300) / 400
						+ hit_object.width;
						/* naka needs another test, so i write a complex (ab')' logic (a:naka b:check). it can be verified by truth table */
						if (yHitTest(hit_object.y, hit_object.height, use_object.y, use_object.height)
						&& (
						    (comment_type == 'naka') && (hit_object.x + hit_object.width > use_object.x || future_x > - use_object.width)
						     || (comment_type != 'naka')
						    )
						)
							{							
								use_object.y = hit_object.y + plus_height_self * use_object.height + plus_height_other * hit_object.height;
								if (use_object.y +use_object.height > PlayerParams.PLAYER_HEIGHT || use_object.y < 0)
								{
									use_object.y  = Math.random() * (Math.max(0, (PlayerParams.PLAYER_HEIGHT - use_object.height)));
									break;
								}
							}						
						}
			/* Return a DisplayObject so it can be recycled */
			return use_object;
		}
		private var _previousTime:int;
		private var _hideItems:int = 0;
		public function updateNakaPosition():void {
			var object:DisplayObject;
			var i:int;
			var startTime:int = getTimer();
			var nowTime:int;
			var commentArea:int = 0;
			for (i = 0; i < this.numChildren; i++) {
				nowTime = getTimer();
				if (nowTime - startTime > 5) { 					
					break;
				}
				object = this.getChildAt(i);
				var field:CommentTextField = object as CommentTextField;
				
				/* To avoid high load for larger comments, make larger comment updates randomly with lower fps */
				if (field.width < 256 || Math.random() * Math.pow(Math.min(field.width / 256, 10) * _previousTime, 2)  < 5) {
					field.x = _nakaInitXOffset + (PlayerParams.PLAYER_WIDTH_4_BY_3 + field.width) * (field.vpos - 100 - this.time) / 400;
					commentArea += field.x * field.y;
				}
				object = null;
			}
			_previousTime = (nowTime - startTime);
		}
		public function updateTime(time:Number):void {
			this.time = time;
			updateNakaPosition();
		}
		public function recycleField(object:DisplayObject):void {
			/* Put it at last, then release it */	
			if (this.numChildren > this.comment_max) throw new Error('Strange!');
			this.setChildIndex(object, this.numChildren - 1);
			(object as CommentTextField).resetFormat();

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

	}
}