package tc.littleb.breezevideo 
{
	/**
	 * Record some constant that will be widely used throught the whole player.
	 * @author littlebtc
	 */
	public class PlayerParams 
	{
		/* Player width & height, under 4:3 and 16:9 mode */
		public static const PLAYER_HEIGHT:int = 384;
		public static const PLAYER_WIDTH_4_BY_3:int = 544;
		public static const PLAYER_WIDTH_16_BY_9:int = 672;
		public static const PLAYER_HORIZONTAL_MARGIN:int = 16;
		
		/* Comment display time. Units are 0.01s. */
		/* "Non-naka" comments should be shown 1 secs before the comment time position,
		 * and hidden 3 secs after that.*/
		public static const SHOW_COMMENT_OFFSET:int = 0;
		public static const HIDE_COMMENT_OFFSET:int = 300;
		
		/* On 4:3 aspect ratio with 544px wide comment sprite,
		 * "Naka" comments should be appeared 1 sec before the comment time position,
		 * and disappeared 3 secs after that.
		 * However, on 16:9 mode, the sprite is wider (672px),
		 * but the "Naka" comments will be treated as they are in 4:3 mode and centered.
		 * So in NicoFox Player, comment will be loaded 1.5 secs before the time position,
		 * and hidden 3.5 secs after that. (extra <0.47*2 secs required) */
		public static const LOAD_NAKA_COMMENT_OFFSET:int = -150;
		public static const SHOW_NAKA_COMMENT_OFFSET:int = -100;
		public static const HIDE_NAKA_COMMENT_OFFSET:int = 300;
		public static const UNLOAD_NAKA_COMMENT_OFFSET:int = 350;
	}

}