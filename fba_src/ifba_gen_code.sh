# burn.h

# burn.cpp

# stdfunc.h

# drv/cps3

# dep/libs/libpng/pngpriv.h

# m68000_intf


#-------------------------------------------------------------------------------
# generate code for specific drivers
#-------------------------------------------------------------------------------
gcc src/burn/drv/capcom/ctv_make.cpp -o src/burn/drv/capcom/ctv_make
src/burn/drv/capcom/ctv_make > src/burn/drv/capcom/ctv.h

perl src/dep/scripts/cave_sprite_func.pl -o src/burn/drv/cave/cave_sprite_func.h
perl src/dep/scripts/cave_tile_func.pl -o src/burn/drv/cave/cave_tile_func.h

perl src/dep/scripts/neo_sprite_func.pl -o src/burn/drv/neogeo/neo_sprite_func.h

gcc src/burn/drv/pgm/pgm_sprite_create.cpp -o src/burn/drv/pgm/pgm_sprite_create
src/burn/drv/pgm/pgm_sprite_create > src/burn/drv/pgm/pgm_sprite.h

perl src/dep/scripts/psikyo_tile_func.pl -o src/burn/drv/psikyo/psikyo_tile_func.h

perl src/dep/scripts/toa_gp9001_func.pl -o src/burn/drv/toaplan/toa_gp9001_func.h

#-------------------------------------------------------------------------------
# generate games and drivers list
#-------------------------------------------------------------------------------
perl src/dep/scripts/gamelist.pl -o src/burn/driverlist.h -l src/burn/gamelist.txt src/burn/drv/ src/burn/drv/capcom/ src/burn/drv/cave/ src/burn/drv/cps3/ src/burn/drv/dataeast/ src/burn/drv/galaxian/ src/burn/drv/irem/ src/burn/drv/konami/ src/burn/drv/megadrive/ src/burn/drv/neogeo/ src/burn/drv/pce/ src/burn/drv/pgm/ src/burn/drv/pre90s/ src/burn/drv/psikyo/ src/burn/drv/pst90s/ src/burn/drv/sega/ src/burn/drv/snes/ src/burn/drv/taito/ src/burn/drv/toaplan/ 

#-------------------------------------------------------------------------------
# add other src (cpu/cyclone, ...)
#-------------------------------------------------------------------------------
cp -R other_src/ src/

## build_details.cpp	fixrc.pl		 ## license2rtf.pl ## gamelist.pl

## 
## 

