
__reg("a3") const char* GetScrollText(__reg("d4") short pageIndex)
{
	switch (pageIndex)
	{
		case 0:
		{
			return "This is\njust\na test\nof";
		}
		case 1:
		{
			return "Variable\nwidth\nfonts\nand\nsprites";
		}
		case 2:
		{
			return "copper\nbars\nand half\nbrite\nimages";
		}
		case 3:
		{
			return "plus\nvarious\nmusic\nplayers";
		}
		case 4:
		{
			return "Lots of\nreused\nassets!\nSorry!";
		}
		case 5:
		{
			return "Now Make\nYour Own\nStuff!";
		}
		case 6:
		{
			return "but\nhow do i\ndo it??";
		}
	}
	return "The\nEnd";
}

