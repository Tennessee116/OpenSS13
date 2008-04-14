

/obj/machinery/meter/New()

	..()
	src.target = locate(/obj/machinery/pipes, src.loc)
	average = 0
	return

/obj/machinery/meter/process()

	if(!target)
		icon_state = "meterX"
		return
	if(stat & NOPOWER)
		icon_state = "meter0"
		return

	use_power(5)

	average = 0.5 * average + 0.5 * target.pl.flow

	var/val = min(18, round( 18.99 * ((abs(average) / 2500000)**0.25)) )
	icon_state = "meter[val]"

/*
/obj/machinery/meter/examine()
	set src in oview(1)

	var/t = "A gas flow meter. "
	if (src.target)
		t += text("Results:\nMass flow []%\nPressure [] kPa", round(100*average/src.target.gas.maximum, 0.1), round(pressure(), 0.1) )
	else
		t += "It is not functioning."

	usr << t

*/

/obj/machinery/meter/Click()

	if (get_dist(usr, src) <= 3)
		if (src.target)
			usr << text("\blue <B>Results:\nMass flow []%\nTemperature [] K</B>", round(100*abs(average)/6e6, 0.1), round(target.pl.gas.temperature,0.1))
		else
			usr << "\blue <B>Results: Connection Error!</B>"
	else
		usr << "\blue <B>You are too far away.</B>"
	return

/*
/obj/machinery/meter/proc/pressure()

	if(src.target && src.target.gas)
		return (average * target.gas.temperature)/100000.0
	else
		return 0
*/


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



