
#define A(x) (((x) & 0xff000000) >> 24)
#define R(x) (((x) & 0x00ff0000) >> 16)
#define G(x) (((x) & 0x0000ff00) >> 8)
#define B(x) ((x) & 0x000000ff)

void alphaBlend_c(int *fgImage, int *bgImage, int *dstImage)
{
  int x, y;
  
  //PLD preloads
  
  
  //try single loop of 512*512
  //less branches etc
  for(y = 0; y < 512; y++){
     for(x = 0; x < 512; x++){
		//calc index
		int index= (y*512) +x;
		
		//four iterations = 4 index calcs at once
		//load from fg and A()
		// right shifting by 24 bits does need and "AND"
        int a_fg = A(fgImage[fg_index]);
		
		//could cross load into lanes
		//i.e. q0 = {fg[i] , bg[i], fg[i], bg[i]}
	
		
		//only load 0xff0000000 etc constants once and use
		
		//same result ued in R,G,B just shifed by different aount
		
		/***********
		//after A,R,B,G only have 8 bit number to worry about
		//doesnt matter if goes over 8-bits since will be masked at end anyway
		// combine into 16-bit registers by ANDing and shifting (two 8 bit numbers 
		// in each 16-bit register(S)
		// I dont think it matters if addressable i.e. using S40 since will same as long
		// as can mask out, or can save until end to use when need access and use high numbers
		// registers in between
		********************///
		
		/*
		255-  number is same as flipping bits of number
		
		use vmov for matrix manipulations
		******///
		
		
		// divide by 256 = >> 7
		//(load from fg , R() it, *a_fg       +       (load from bg, R() it, *(255-a_fg)/)256
        int dst_r = ((R(fgImage[index]) * a_fg) + (R(bgImage[index]) * (255-a_fg)))/256;
        int dst_g = ((G(fgImage[index]) * a_fg) + (G(bgImage[index]) * (255-a_fg)))/256;
        int dst_b = ((B(fgImage[index]) * a_fg) + (B(bgImage[index]) * (255-a_fg)))/256;
		
		
		//figure out what this is doing in combination with A,R,G,B 
		//may be able to cleverly extact with vfp instrucitons rather than shift
		
		//extracting 8 bits from each and combining
		//dst = (0xFF,dst_r{16-23},dst_g{8-15},dst_b{0-7}
        dstImage[index] =  0xff000000 |
                              (0x00ff0000 & (dst_r << 16)) |
                              (0x0000ff00 & (dst_g << 8)) |
                              (0x000000ff & (dst_b));
     }
  }
}