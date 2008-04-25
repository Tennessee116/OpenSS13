
/obj/machinery/mass_driver/proc/drive(amount)

	if(stat & NOPOWER)
		return

	use_power(500)
	for(var/obj/O in src.loc)
		if (O.flags & 64)
			O.throwing = 1
			O.throwspeed = 100
			spawn( 0 )
				O.throwing(src.dir, src.power)
				return
		//Foreach goto(17)
	flick("mass_driver1", src)
	return



