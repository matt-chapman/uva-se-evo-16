module VolumeAnalysis

public int makeVolumeRank(num lines)
{
	num klines = lines / 1000;
	
	//++  0-66
	//+   66-246
	//o   246-665 
	//-   655-1,310 
	//--  > 1,310 
	
	if( klines > 0 && klines <= 66)
	{
		return 4;
	}
	else if ( klines >= 67 && klines <= 246)
	{
		return 3;
	}
	else if ( klines >= 247 && klines <= 665)
	{
		return 2;
	}
	else if ( klines >= 656 && klines <= 1310)
	{
		return 1;
	}
	else if ( klines > 1310)
	{
		return 0;
	}
}