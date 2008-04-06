// pipeline datum for storings inter-machine links


// create a pipeline

/obj/machinery/pipeline/New()
	..()

	gas = new/obj/substance/gas(src)
	ngas = new/obj/substance/gas()

	gasflowlist += src

// find the pipeline that contains the /obj/machine (including pipe)
/proc/findline(var/obj/machinery/M)

	for(var/obj/machinery/pipeline/P in plines)

		for(var/obj/machinery/O in P.nodes)

			if(M==O)
				return P

	return null

// sets the vnode1&2 terminators to the joining machines (or null)
/obj/machinery/pipeline/proc/setterm()

	//first make sure pipes are oriented correctly

	var/obj/machinery/M = null

	for(var/obj/machinery/pipes/P in nodes)
		if(!M)			// special case for 1st pipe
			if(P.node1 && P.node1.ispipe())
				P.flip()		// flip if node1 is a pipe
		else
			if(P.node1 != M)		//other cases, flip if node1 doesn't point to previous node
				P.flip()			// (including if it is null)


		M = P


	// pipes are now ordered so that n1/n2 is in same order as pipeline list

	var/obj/machinery/pipes/P = nodes[1]		// 1st node in list
	vnode1 = P.node1							// n1 points to 1st machine
	P = nodes[nodes.len]						// last node in list
	vnode2 = P.node2							// n2 points to last machine


	return


/obj/machinery/pipeline/get_gas_val(from)
	return gas.tot_gas()/capmult

/obj/machinery/pipeline/get_gas(from)
	return gas



/obj/machinery/pipeline/gas_flow()

	//if(suffix == "d" && Debug) world.log << "PLF1  [gas.tot_gas()] ~ [ngas.tot_gas()]"

	gas.replace_by(ngas)

	//if(suffix == "d" && Debug) world.log << "PLF2  [gas.tot_gas()] ~ [ngas.tot_gas()]"

/obj/machinery/pipeline/process()

	// heat exchange for whole pipeline

	//if(suffix=="dbgp")
	//	world.log << "PLP"
	//	Plasma()

//	var/dbg = (suffix == "d") && Debug

	//if(dbg) world.log << "PLP1 [gas.tot_gas()] ~ [ngas.tot_gas()]"


	var/gtemp = ngas.temperature					// cached temperature for heat exch calc
	var/tot_node = ngas.tot_gas() / numnodes		// fraction of gas in this node

	//if(dbg) world.log << "PLHE: [gtemp] [tot_node]"

	if(tot_node>0.1)		// no pipe contents, don't heat
		for(var/obj/machinery/pipes/P in src.nodes)		// for each segment of pipe
			P.heat_exchange(ngas, tot_node, numnodes, gtemp) //, dbg)	// exchange heat with its turf


	// now do standard gas flow proc


	//if(dbg) world.log << "PLP2 [ngas.tot_gas()]"

	var/delta_gt

	if(vnode1)
		delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode1, delta_gt)//, dbg)

		//if(dbg) world.log << "PLT1 [delta_gt] >> [gas.tot_gas()] ~ [ngas.tot_gas()]"

		flow = delta_gt
	else
		leak_to_turf(1)

	if(vnode2)
		delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode2, delta_gt)//, dbg)

		//if(dbg) world.log << "PLT2 [delta_gt] >> [gas.tot_gas()] ~ [ngas.tot_gas()]"

		flow -= delta_gt
	else
		leak_to_turf(2)



/obj/machinery/pipeline/proc/leak_to_turf(var/port)

	var/turf/T
	var/obj/machinery/pipes/P
	var/list/ndirs

	switch(port)
		if(1)
			P = nodes[1]		// 1st node in list
			ndirs = P.get_node_dirs()

			T = get_step(P, ndirs[1])


		if(2)
			P = nodes[nodes.len]	// last node in list

			ndirs = P.get_node_dirs()
			T = get_step(P, ndirs[2])

	if(T.density)
		return

	flow_to_turf(gas, ngas, T)


// build the pipelines
/proc/makepipelines()

	var/linecount = 0		// the line number

	for(var/obj/machinery/pipes/P in machines)		// look for a pipe

		if(!P.plnum)							// if not already part of a line
			P.buildnodes(++linecount)			// add it, and spread to all connected pipes

			//world.log<<"Line #[linecount] started at [P] ([P.x],[P.y],[P.z])"


	for(var/L = 1 to linecount)					// for count of lines found
		var/obj/machinery/pipeline/PL = new()	// make a pipeline virtual object
		PL.name = "pipeline #[L]"
		plines += PL							// and add it to the list



	for(var/obj/machinery/pipes/P in machines)		// look for pipes

		if(P.termination)						// true if pipe is terminated (ends in blank or a machine)
			var/obj/machinery/pipeline/PL = plines[P.plnum]		// get the pipeline from the pipe's pl-number

			var/list/pipes = pipelist(null, P)	// get a list of pipes from P until terminated

			PL.nodes = pipes					// pipeline is this list of nodes
			PL.numnodes = pipes.len				// with this many nodes
			PL.capmult = PL.numnodes+1	// with this flow multiplier



	for(var/obj/machinery/pipes/P in machines)		// all pipes
		P.setline()								// 	set the pipeline object for this pipe

		if(P.tag == "dbg")		//add debug tag to line containing debug pipe
			P.pl.tag = "dbg"

		if(P.suffix == "dbgpp")		//add debug tag to line containing debug pipe
			P.pl.suffix = "dbgp"

		if(P.suffix == "d")		//add debug tag to line containing debug pipe
			P.pl.suffix = "d"


	for(var/obj/machinery/M in machines)			// for all machines
		if(M.p_dir)								// which are pipe-connected
			if(!M.ispipe())						// is not a pipe itself
				M.buildnodes()					// build the nodes, setting the links to the virtual pipelines
												// also sets the vnodes for the pipelines

	for(var/obj/machinery/pipeline/PL in plines)	// for all lines
		PL.setterm()								// orient the pipes and set the pipeline vnodes to the terminating machines

// return a list of pipes (not including terminating machine)

/proc/pipelist(var/obj/machinery/source, var/obj/machinery/startnode)

	var/list/L = list()

	var/obj/machinery/node = startnode
	var/obj/machinery/prev = source
	var/obj/machinery/newnode

	while(node)
		L += node
		newnode = node.next(prev)
		prev = node

		if(newnode && newnode.ispipe())
			node = newnode
		else
			break

	return L

// new pipes system

// flip the nodes of a pipe
/obj/machinery/pipes/proc/flip()

	var/obj/machinery/tempnode = node1
	node1 = node2
	node2 = tempnode
	return


// return the next pipe in the node chain
/obj/machinery/pipes/next(var/obj/machinery/from)

	if(from == null)		// if from null, then return the next actual pipe
		if(node1 && node1.ispipe() )
			return node1
		if(node2 && node2.ispipe() )
			return node2
		return null			// else return null if no real pipe connected

	else if(from == node1)		// otherwise, return the node opposite the incoming one
		return node2
	else
		return node1


// set the pipeline obj from the pl-number and global list of pipelines

/obj/machinery/pipes/setline()
	src.pl = plines[plnum]
	return

// returns the pipeline that this line is in

/obj/machinery/pipes/getline()
	return pl

/obj/machinery/pipes/orient_pipe(P as obj)

	if (!( src.node1 ))
		src.node1 = P
	else
		if (!( src.node2 ))
			src.node2 = P
		else
			return 0
	return 1

// returns a list of dir1, dir2 & p_dir for a pipe

/obj/machinery/pipes/proc/get_dirs()
	var/b1
	var/b2

	for(var/d in cardinal)
		if(p_dir & d)
			if(!b1)
				b1 = d
			else if(!b2)
				b2 = d

	return list(b1, b2, p_dir)

// returns a list of the directions of a pipe, matched to nodes (if present)

/obj/machinery/pipes/proc/get_node_dirs()
	var/list/dirs = get_dirs()


	if(!node1 && !node2)		// no nodes - just return the standard dirs
		return dirs				// note extra p_dir on end of list is unimportant
	else
		if(node1)
			var/d1 = get_dir(src, node1)		// find the direction of node1
			if(d1==dirs[1])						// if it matches
				return dirs						// then dirs list is correct
			else
				return list(dirs[2], dirs[1])	// otherwise return the list swapped

		else		// node2 must be valid
			var/d2 = get_dir(src, node2)		// direction of node2
			if(d2==dirs[2])						// matches
				return dirs						// dirs list is correct
			else
				return list(dirs[2], dirs[1])	// otherwise swap order


/obj/machinery/pipes/proc/update()

	var/turf/T = src.loc

	var/list/dirs = get_dirs()

	var/is = "[dirs[3]]"

	if(stat & BROKEN)
		is += "-b"

	if ((src.level == 1 && isturf(src.loc) && T.intact))
		src.invisibility = 101
		is += "-f"

	else
		src.invisibility = null

	src.icon_state = is

	if(node1 && node2)
		overlays = null
	else if(!node1 && !node2)
		overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[1])
		overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[2])
	else if(!node1)
		var/d2 = get_dir(src, node2)
		if(dirs[1] == d2)
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[2])
		else
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[1])
	else if(!node2)
		var/d1 = get_dir(src, node1)
		if(dirs[1] == d1)
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[2])
		else
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[1])


	return

/obj/machinery/pipes/hide(var/i)

	update()

/obj/machinery/pipes/proc/explode()

	//*****
//	world << "pipe [src] at [x],[y],[z] exploded"

//	src.gas.turf_add(src.loc, -1.0)
	return


/*
/obj/machinery/pipes/process()
*/

/obj/machinery/pipes/New()

	..()

	if(istype(src, /obj/machinery/pipes/heat_exch))
		h_dir = text2num(icon_state)
	else
		p_dir = text2num(icon_state)


/obj/machinery/pipes/ispipe()		// return true since this is a pipe
	return 1

/obj/machinery/pipes/buildnodes(var/linenum)

	if(plnum)
		return

	var/list/dirs = get_dirs()

	node1 = get_machine(level, src.loc, dirs[1])
	node2 = get_machine(level, src.loc, dirs[2])

	update()

	plnum = linenum

	termination = 0

	if(node1 && node1.ispipe() )

		node1.buildnodes(linenum)
	else
		termination++

	if(node2 && node2.ispipe() )
		node2.buildnodes(linenum)
	else
		termination++


/obj/machinery/pipes/heat_exch/get_dirs()
	var/b1
	var/b2

	for(var/d in cardinal)
		if(h_dir & d)
			if(!b1)
				b1 = d
			else if(!b2)
				b2 = d

	return list(b1, b2, h_dir)

/obj/machinery/pipes/heat_exch/buildnodes(var/linenum)

	if(plnum)
		return

	src.level = 2		// h/e pipe cannot be put underfloor

	var/list/dirs = get_dirs()

	node1 = get_he_machine(level, src.loc, dirs[1])
	node2 = get_he_machine(level, src.loc, dirs[2])

	update()

	plnum = linenum

	termination = 0

	if(node1 && node1.ispipe() )

		node1.buildnodes(linenum)
	else
		termination++

	if(node2 && node2.ispipe() )
		node2.buildnodes(linenum)
	else
		termination++


/obj/machinery/pipes/proc/heat_exchange(var/obj/substance/gas/gas, var/tot_node, var/numnodes, var/temp, var/dbg=0)


	var/turf/T = src.loc		// turf location of pipe
	if(T.density) return

	if( level != 1)				// no heat exchange for under-floor pipes
		if(istype(T,/turf/space))		// heat exchange less efficient in space (no conduction)
			gas.temperature += ( T.temp - temp) / (3.0 * insulation * numnodes)
		else

	//		if(dbg) world.log << "PHE: ([x],[y]) [T.temp]-> \..."
			var/delta_T = (T.temp - temp) / (insulation)	// normal turf

			gas.temperature += delta_T	/ numnodes			// heat the pipe due to turf temperature

			/*
			if(abs(delta_T*tot_node/T.tot_gas()) > 1)
				world.log << "Turf [T] at [T.x],[T.y]: gt=[temp] tt=[T.temp]"
				world.log << "dT = [delta_T] tn=[tot_node] ttg=[T.tot_gas()] tt-=[delta_T*tot_node/T.tot_gas()]"

			*/
			var/tot_turf = max(1, T.tot_gas())
			T.temp -= delta_T*min(10,tot_node/tot_turf)			// also heat the turf due to pipe temp
							// clamp max temp change to prevent thermal runaway
							// if low amount of gas in turf
	//		if(dbg) world.log << "[T.temp] [tot_turf] #[delta_T]"
			T.res_vars()	// ensure turf tmp vars are updated

	else								// if level 1 but in space, perform cooling anyway - exposed pipes
		if(istype(T,/turf/space))
			gas.temperature += ( T.temp - temp) / (3.0 * insulation * numnodes)



// amount of gas that can be received = pipe capacity - amount already present
/*
/obj/machinery/pipes/receive_amount()
	if(gas)
		return max(0, capacity - gas.tot_gas())
	return 0

/obj/machinery/pipes/receive_gas(var/obj/substance/gas/t_gas as obj, from as obj, amount)
	//new pipe logic
	// src receives (up to) 'amount' of gas 't_gas' from 'from'
	// uses receive_amount to find actual amount of gas to transfer
	// note any excess must bem left in from.gas - need t_gas = from.gas


	amount = max(0, min( amount, src.receive_amount(src) ))	// limit amount of gas transfered to that able to receive

	gas.transfer_from(t_gas, amount)	// transfer from incoming gas to local gas reservoir. Remainder left in t_gas

	var/tot = gas.tot_gas()		// total amount of gas now in reservoir

	var/turf/T = src.loc		// turf location of pipe

	if( level != 1)				// no heat exchange for under-floor pipes
		if(istype(T,/turf/space))		// heat exchange less efficient in space (no conduction)
			gas.temperature += ( T.temp - gas.temperature) / (3.0 * insulation)
		else
			var/delta_T = (T.temp - gas.temperature) / insulation	// normal turf
			gas.temperature += delta_T								// heat the pipe due to turf temperature

			T.temp -= delta_T*tot/T.tot_gas()						// also heat the turf due to pipe temp

	last_flow = amount		// for metering of flow rate

	spawn( 2 )

		if (from == src.node1)		// recieved from node1
			spawn( 0 )
				if(node2)
					src.node2.receive_gas(gas, src, tot*PIPEFRAC)	// so forward to node2, if present
				else
					src.leak_to_turf()		// otherwise leak
				return
		else
			spawn( 0 )
				if(node1)
					src.node1.receive_gas(gas, src, tot*PIPEFRAC)
				else
					src.explode()
				return

	return


*/



// finds the machine with compatible p_dir in 1 step in dir from S
/proc/get_machine(var/level, var/turf/S, mdir)

	var/flip = turn(mdir, 180)

	var/turf/T = get_step(S, mdir)

	for(var/obj/machinery/M in T.contents)
		if(M.level == level)
			if(M.p_dir & flip)
				return M

	return null

// finds the machine with compatible h_dir in 1 step in dir from S
/proc/get_he_machine(var/level, var/turf/S, mdir)

	var/flip = turn(mdir, 180)

	var/turf/T = get_step(S, mdir)

	for(var/obj/machinery/M in T.contents)
		if(M.level == level)
			if(M.h_dir & flip)
				return M

	return null




// ***** circulator

/obj/machinery/circulator/New()
	..()
	gas1 = new/obj/substance/gas(src)
	gas1.maximum = capacity
	gas2 = new/obj/substance/gas(src)
	gas2.maximum = capacity

	ngas1 = new/obj/substance/gas()
	ngas2 = new/obj/substance/gas()

	gasflowlist += src

	//gas.co2 = capacity

	updateicon()

/obj/machinery/circulator/buildnodes()

	var/turf/TS = get_step(src, SOUTH)
	var/turf/TN = get_step(src, NORTH)

	for(var/obj/machinery/M in TS)

		if(M && (M.p_dir & 1))
			node1 = M
			break

	for(var/obj/machinery/M in TN)

		if(M && (M.p_dir & 2))
			node2 = M
			break


	if(node1) vnode1 = node1.getline()

	if(node2) vnode2 = node2.getline()


/*
/obj/machinery/circulator/verb/toggle_power()
	set src in view(1)

	if(status == 1)
		status = 2
		spawn(30)				// 3 second delay for slow-off
			if(status == 2)
				status = 0
				updateicon()
	else if(status == 0)
		status =1

	updateicon()



/obj/machinery/circulator/verb/set_rate(r as num)
	set src in view(1)
	rate = r/100.0*capacity
*/

/obj/machinery/circulator/proc/control(var/on, var/prate)

	rate = prate/100*capacity

	if(status == 1)
		if(!on)
			status = 2
			spawn(30)
				if(status == 2)
					status = 0
					updateicon()
	else if(status == 0)
		if(on)
			status = 1
	else	// status ==2
		if(on)
			status = 1

	updateicon()


/obj/machinery/circulator/proc/updateicon()

	if(stat & NOPOWER)
		icon_state = "circ[side]-p"
		return

	var/is
	switch(status)
		if(0)
			is = "off"
		if(1)
			is = "run"
		if(2)
			is = "slow"

	icon_state = "circ[side]-[is]"



/obj/machinery/circulator/power_change()
	..()
	updateicon()

/*
/obj/machinery/circulator/receive_gas(var/obj/substance/gas/t_gas as obj, from as obj, amount)


	if(from != src.node1)
		return

	amount = min(receive_amount(src), amount)


	//src.gas.transfer_from(t_gas, amount)

	return
*/
/obj/machinery/circulator/gas_flow()

	gas1.replace_by(ngas1)
	gas2.replace_by(ngas2)

/obj/machinery/circulator/process()

	// if operating, pump from resv1 to resv2

	if(! (stat & NOPOWER) )				// only do circulator step if powered; still do rest of gas flow at all times
		if(status==1 || status==2)
			gas2.transfer_from(gas1, status==1? rate : rate/2)
			use_power(rate/capacity * 100)
		ngas1.replace_by(gas1)
		ngas2.replace_by(gas2)


	// now do standard process

	var/delta_gt

	if(vnode1)
		delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas1.tot_gas() / capmult)
		calc_delta( src, gas1, ngas1, vnode1, delta_gt)
	else
		leak_to_turf(1)

	if(vnode2)
		delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas2.tot_gas() / capmult)
		calc_delta( src, gas2, ngas2, vnode2, delta_gt)
	else
		leak_to_turf(2)


/obj/machinery/circulator/proc/leak_to_turf(var/port)

	var/turf/T

	switch(port)
		if(1)
			T = get_step(src, SOUTH)
		if(2)
			T = get_step(src, NORTH)

	if(T.density)
		T = src.loc
		if(T.density)
			return

	switch(port)
		if(1)
			flow_to_turf(gas1, ngas1, T)
		if(2)
			flow_to_turf(gas2, ngas2, T)


	// do leak



/obj/machinery/circulator/get_gas_val(from)

	if(from == vnode1)
		return gas1.tot_gas()/capmult
	else
		return gas2.tot_gas()/capmult

/obj/machinery/circulator/get_gas(from)

	if(from == vnode1)
		return gas1
	else
		return gas2

// *** pipe manifold


/obj/machinery/manifold/New()

	..()

	switch(dir)
		if(NORTH)
			p_dir = 13 //NORTH|EAST|WEST

		if(SOUTH)
			p_dir = 14 //SOUTH|EAST|WEST

		if(EAST)
			p_dir = 7 //EAST|NORTH|SOUTH

		if(WEST)
			p_dir = 11 //WEST|NORTH|SOUTH



	src.gas = new /obj/substance/gas( src )
	src.gas.maximum = src.capacity
	src.ngas = new /obj/substance/gas()
	gasflowlist += src


/obj/machinery/manifold/buildnodes()

	var/turf/T = src.loc

	node3 = get_machine( level, T, dir )		// the injector port

	n1dir = turn(dir, 90)
	n2dir = turn(dir,-90)

	node1 = get_machine( level, T , n1dir )	// the main flow dir


	node2 = get_machine( level, T , n2dir )


	if(node1) vnode1 = node1.getline()
	if(node2) vnode2 = node2.getline()
	if(node3) vnode3 = node3.getline()

	return


/obj/machinery/manifold/gas_flow()

	gas.replace_by(ngas)

/obj/machinery/manifold/process()

	var/delta_gt

	if(vnode1)
		delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode1, delta_gt)
	else
		leak_to_turf(1)

	if(vnode2)
		delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode2, delta_gt)
	else
		leak_to_turf(2)

	if(vnode3)
		delta_gt = FLOWFRAC * ( vnode3.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode3, delta_gt)
	else
		leak_to_turf(3)


/obj/machinery/manifold/get_gas_val(from)
	return gas.tot_gas()/capmult

/obj/machinery/manifold/get_gas(from)
	return gas


/obj/machinery/manifold/proc/leak_to_turf(var/port)

	var/turf/T


	switch(port)
		if(1)
			T = get_step(src, n1dir)
		if(2)
			T = get_step(src, n2dir)
		if(3)
			T = get_step(src, dir)

	if(T.density)
		T = src.loc
		if(T.density)
			return

	flow_to_turf(gas, ngas, T)

	//	delta = 0





/obj/machinery/connector/New()

	..()

	gas = new/obj/substance/gas(src)
	gas.maximum = capacity
	ngas = new/obj/substance/gas()
	//agas = new/obj/substance/gas()

	gasflowlist += src
	spawn(5)
		var/obj/machinery/atmoalter/A = locate(/obj/machinery/atmoalter, src.loc)

		if(A && A.c_status != 0)
			connected = A
			A.anchored = 1



/obj/machinery/connector/buildnodes()

	var/turf/T = get_step(src.loc, src.dir)
	var/fdir = turn(src.p_dir, 180)

	for(var/obj/machinery/M in T)
		if(M.p_dir & fdir)
			src.node = M
			break

	if(node) vnode = node.getline()


	return



/obj/machinery/connector/examine()
	set src in oview(1)

	if(connected)
		usr << "A pipe connector for gas equipment. It is connected to \an [connected.name]."
	else
		usr << "A pipe connector for gas equipment. It is unconnected."



/obj/machinery/connector/get_gas_val(from)
	return gas.tot_gas()/capmult

/obj/machinery/connector/get_gas(from)
	return gas


/obj/machinery/connector/gas_flow()

//	var/dbg = (suffix == "d") && Debug
	//if(dbg) world.log << "CF0: ngas=[ngas.tot_gas()]"

	//ngas.transfer_from(agas, -1)

	//if(dbg)	world.log << "CF1: ngas=[gas.tot_gas()]"
	gas.replace_by(ngas)
	//if(dbg)	world.log << "CF2: gas=[gas.tot_gas()]"
	flag = 0

/obj/machinery/connector/process()

	//if(suffix=="dbgp")
	//	world.log << "CP"
	//	Plasma()

	var/delta_gt
//	var/dbg = (suffix == "d") && Debug

	//if(dbg) world.log << "C[tag]P: [gas.tot_gas()] ~ [ngas.tot_gas()]"
	//if(dbg && connected) world.log << "C[tag]PC: [connected.gas.tot_gas()]"

	if(vnode)

		delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)
		//if(dbg) world.log << "C[tag]P0: [delta_gt]"

		//var/obj/substance/gas/vgas = vnode.get_gas(src)

		//if(dbg) world.log << "C[tag]P1: [gas.tot_gas()], [ngas.tot_gas()] -> [vgas.tot_gas()]"
		calc_delta( src, gas, ngas, vnode, delta_gt)//, dbg)
		//if(dbg) world.log << "C[tag]P2: [gas.tot_gas()], [ngas.tot_gas()] -> [vgas.tot_gas()]"

	else
		leak_to_turf()

	if(connected)
		var/amount
		if(connected.c_status == 1)				// canister set to release

			//if(dbg) world.log << "C[tag]PC1: [gas.tot_gas()], [ngas.tot_gas()] <- [connected.gas.tot_gas()]"
			amount = min(connected.c_per, capacity - gas.tot_gas() )	// limit to space in connector
			amount = max(0, min(amount, connected.gas.tot_gas() ) )		// limit to amount in canister, or 0
			//if(dbg) world.log << "C[tag]PC2: a=[amount]"
			//var/ng = ngas.tot_gas()
			ngas.transfer_from( connected.gas, amount)
			//if(dbg) world.log <<"[ngas.tot_gas()-ng] from siph to connector"
			//if(dbg) world.log << "C[tag]PC3: [gas.tot_gas()], [ngas.tot_gas()] <- [connected.gas.tot_gas()]"
		else if(connected.c_status == 2)		// canister set to accept

			amount = min(connected.c_per, connected.gas.maximum - connected.gas.tot_gas())	//limit to space in canister
			amount = max(0, min(amount, gas.tot_gas() ) )				// limit to amount in connector, or 0

			connected.gas.transfer_from( ngas, amount)

	//flag = 1

	//if(suffix=="dbgp")
	//	world.log << "CP"
	//	Plasma()




/obj/machinery/connector/proc/leak_to_turf()

	//var/dbg = (tag == "dbg") && Debug

	var/turf/T = get_step(src, dir)
	if(T && !T.density)

		//if(dbg) world.log << "CLT1: [gas.tostring()] ~ [ngas.tostring()]\nTg = [T.tostring()]"


		flow_to_turf(gas, ngas, T)

		//if(dbg) world.log << "CLT2: [gas.tostring()] ~ [ngas.tostring()]\nTg = [T.tostring()]"



/obj/machinery/junction/New()
	..()
	gas = new/obj/substance/gas(src)
	ngas = new/obj/substance/gas()
	gasflowlist += src

	h_dir = dir					// the h/e pipe is in obj dir
	p_dir = turn(dir, 180)		// the reg pipe is in opposite dir


/obj/machinery/junction/buildnodes()

	var/turf/T = src.loc

	node1 = get_he_machine(level, T, h_dir )		// the h/e pipe

	node2 = get_machine(level, T , p_dir )	// the regular pipe

	if(node1) vnode1 = node1.getline()
	if(node2) vnode2 = node2.getline()

	return


/obj/machinery/junction/gas_flow()

	//var/dbg
	//if(tag == "dbg1")
	//	dbg = 1
	//else if(tag == "dbg2")
	//	dbg = 2

	//if(dbg)	world.log << "J[dbg]F1: [gas.tostring()] ~ [ngas.tostring()]"


	gas.replace_by(ngas)

	//if(dbg)	world.log << "J[dbg]F2: [gas.tostring()] ~ [ngas.tostring()]"

/obj/machinery/junction/process()

	//var/dbg
	//if(tag == "dbg1")
	//	dbg = 1
	//else if(tag == "dbg2")
	//	dbg = 2

	//if(dbg)	world.log << "J[dbg]P: [gas.tostring()] ~ [ngas.tostring()]"

	var/delta_gt

	if(vnode1)
		delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode1, delta_gt) //, dbg)

	//	if(dbg)	world.log << "J[dbg]T1: [delta_gt] >> [gas.tostring()] ~ [ngas.tostring()]"
	else
		leak_to_turf(1)

	if(vnode2)
		delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas.tot_gas() / capmult)
		calc_delta( src, gas, ngas, vnode2, delta_gt) //, dbg)

	//	if(dbg)	world.log << "J[dbg]T2: [delta_gt] >> [gas.tostring()] ~ [ngas.tostring()]"
	else
		leak_to_turf(2)


/obj/machinery/junction/get_gas_val(from)
	return gas.tot_gas()/capmult

/obj/machinery/junction/get_gas(from)
	return gas

/obj/machinery/junction/proc/leak_to_turf(var/port)

	var/turf/T


	switch(port)
		if(1)
			T = get_step(src, dir)
		if(2)
			T = get_step(src, turn(dir, 180) )

	if(T.density)
		T = src.loc
		if(T.density)
			return

	flow_to_turf(gas, ngas, T)



/proc/calc_delta(obj/machinery/source, obj/substance/gas/sgas, obj/substance/gas/sngas, obj/machinery/target, amount, dbg=0)

	var/obj/substance/gas/tgas = target.get_gas(source)

	var/obj/substance/gas/ndelta = new()

	/*if(dbg)
		if(amount>0)
			world.log << "[num2text(amount,10)] from [target] to [source]"
		else
			world.log << "[num2text(-amount,10)] from [source] to [target]"
		dbg = 0
	*/
	//if(dbg) world.log << "CalcDelta: [source] ~ [sgas.tostring()] ~ [sngas.tostring()]\n[target] ~ [tgas.tostring()]  : [amount]"


	if(amount < 0)		// then flowing from source to target

	//	if(dbg)
	//		world.log << "[amount]<0"

		ndelta.set_frac(sgas, -amount)		// this is fraction of the gas which will be transfered to other node

	//	if(dbg)
	//		world.log << "ND: [ndelta.tostring()]"


		sngas.sub_delta(ndelta)		// subtract off the fraction which is gone

	//	if(dbg)
	//		world.log << "SND: [sngas.tostring()]"

	else				// flowing from target to source
	//	if(dbg)
	//		world.log << "[amount]>0"

		ndelta.set_frac(tgas, amount)		// fraction of gas from the other node
	//	if(dbg)
	//		world.log << "ND: [ndelta.tostring()]"

		sngas.add_delta(ndelta)				// add the fraction to the new gas resv
	//	if(dbg)
	//		world.log << "SND: [sngas.tostring()]"


/obj/substance/gas/proc/tostring()
	return "Tot: [src.tot_gas()] ; [oxygen]/[n2]/#[plasma]/[co2]/[sl_gas] ; Temp:[temperature]"


/obj/machinery/vent/New()

	..()
	p_dir = dir
	gas = new/obj/substance/gas(src)
	gas.maximum = capacity
	ngas = new/obj/substance/gas()
	gasflowlist += src


/obj/machinery/vent/buildnodes()

	var/turf/T = get_step(src.loc, src.dir)
	var/fdir = turn(src.p_dir, 180)

	for(var/obj/machinery/M in T)
		if(M.p_dir & fdir)
			src.node = M
			break

	if(node) vnode = node.getline()

	return


/obj/machinery/vent/get_gas_val(from)
	return gas.tot_gas()/2

/obj/machinery/vent/get_gas(from)
	return gas


/obj/machinery/vent/gas_flow()

//	var/dbg = (suffix=="d") && Debug
	//if(dbg) world.log << "V[tag]F1: [gas.tot_gas()] ~ [ngas.tot_gas()]"
	gas.replace_by(ngas)
	//if(dbg) world.log << "V[tag]F2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

/obj/machinery/vent/process()


//	var/dbg = (suffix=="d") && Debug
	//if(dbg)	world.log << "V[tag]T1: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	//if(suffix=="dbgp")
	//	world.log << "VP"
	//	Plasma()

	var/delta_gt

	var/turf/T = src.loc

	delta_gt = FLOWFRAC * (gas.tot_gas() / capmult)
	//var/ng = ngas.tot_gas()
	ngas.turf_add(T, delta_gt)

	//if(dbg) world.log << "[num2text(ng-ngas.tot_gas(),10)] from vent to turf"
	//if(dbg)	world.log << "V[tag]T2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	if(vnode)

		//if(dbg)	world.log << "V[tag]N1: [gas.tot_gas()] ~ [ngas.tot_gas()]"

		delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)

		calc_delta( src, gas, ngas, vnode, delta_gt)//, dbg)

		//if(dbg)	world.log << "V[tag]N2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	else
		leak_to_turf()



/obj/machinery/vent/proc/leak_to_turf()
// note this is a leak from the node, not the vent itself
// thus acts as a link between the vent turf and the turf in step(dir)

	var/turf/T = get_step(src, dir)
	if(T && !T.density)
		flow_to_turf(gas, ngas, T)


// inlet - equilibrates between pipe contents and turf
// very similar to vent, except that a vent always dumps pipe gas into turf
/obj/machinery/inlet/New()

	..()

	p_dir = dir
	gas = new/obj/substance/gas(src)
	gas.maximum = capacity
	ngas = new/obj/substance/gas()
	gasflowlist += src


/obj/machinery/inlet/buildnodes()

	var/turf/T = get_step(src.loc, src.dir)
	var/fdir = turn(src.p_dir, 180)

	for(var/obj/machinery/M in T)
		if(M.p_dir & fdir)
			src.node = M
			break

	if(node) vnode = node.getline()

	return


/obj/machinery/inlet/get_gas_val(from)
	return gas.tot_gas()/2

/obj/machinery/inlet/get_gas(from)
	return gas


/obj/machinery/inlet/gas_flow()

	var/dbg = (suffix=="d") && Debug
	if(dbg) world.log << "I[tag]F1: [gas.tot_gas()] ~ [ngas.tot_gas()]"
	gas.replace_by(ngas)
	if(dbg) world.log << "I[tag]F2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

/obj/machinery/inlet/process()


	var/dbg = (suffix=="d") && Debug
	if(dbg)	world.log << "I[tag]T1: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	//if(suffix=="dbgp")
	//	world.log << "VP"
	//	Plasma()

	var/delta_gt

	var/turf/T = src.loc

	// this is the difference between vent and inlet

	if(T && !T.density)
		flow_to_turf(gas, ngas, T, dbg)		// act as gas leak

	if(dbg)	world.log << "I[tag]T2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	if(vnode)

		//if(dbg)	world.log << "V[tag]N1: [gas.tot_gas()] ~ [ngas.tot_gas()]"

		delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)

		calc_delta( src, gas, ngas, vnode, delta_gt)//, dbg)

		//if(dbg)	world.log << "V[tag]N2: [gas.tot_gas()] ~ [ngas.tot_gas()]"

	else
		leak_to_turf()



/obj/machinery/inlet/proc/leak_to_turf()
// note this is a leak from the node, not the inlet itself
// thus acts as a link between the inlet turf and the turf in step(dir)

	var/turf/T = get_step(src, dir)
	if(T && !T.density)
		flow_to_turf(gas, ngas, T)



// standard proc for all machines - passed gas/ngas as arguments
// equilibrate a pipe object and a turf's gas content

/obj/machinery/proc/flow_to_turf(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T, var/dbg = 0)

	if(dbg) world.log << "FTT: G=[sgas.tostring()] ~ N=[sngas.tostring()]"
	if(dbg) world.log << "T=[T.tostring()]"



	var/t_tot = T.tot_gas() * 0.2		// partial pressure of turf gas at pipe, for the moment

	var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )

	if(dbg) world.log << "FTT: dgt=[delta_gt]"

	var/obj/substance/gas/ndelta = new()

	if(delta_gt < 0)	// flow from pipe to turf

		//world.log << "FTT<0"
		ndelta.set_frac(sgas, -delta_gt)		// ndelta contains gas to transfer to turf
		//world.log << "ND=[ndelta.tostring()]"
		sngas.sub_delta(ndelta)			// update new gas to remove the amount transfered
		//world.log << "SN=[sngas.tostring()]"
		ndelta.turf_add(T, -1)		// add all of ndelta to turf
		//world.log << "T=[T.tostring()]"

		//world.log << "LTT: [num2text(-delta_gt,10)] from [sgas.loc] to turf"


	else				// flow from turf to pipe
		if(dbg) world.log << "FTT>0"

		sngas.turf_take(T, delta_gt)		// grab gas from turf and direcly add it to the new gas
		if(dbg) world.log << "SN=[sngas.tostring()]"
		if(dbg) world.log << "T=[T.tostring()]"

		if(dbg) world.log << "LTT: [num2text(delta_gt,10)] from turf to [sgas.loc]"

	T.res_vars()	// update turf gas vars for both cases



/turf/proc/tostring()
	var/obj/substance/gas/G = src.get_gas()
	return G.tostring()

/proc/Plasma()

	var/mplas = 0

	for(var/obj/machinery/M in machines)
		if(M.suffix=="dbgp")

			var/obj/substance/gas/G = M.get_gas()
			var/p = G.plasma

			mplas += p

			world.log << "[M]=[num2text(p, 10)]  \..."


	var/tplas = 0

	for(var/turf/station/engine/floor/T in world)
		tplas += T.poison

	world.log << "\nTotals: M=[num2text(mplas, 10)] T=[num2text(tplas, 10)], all = [num2text(mplas+tplas, 10)]"



// on-off valve

/obj/machinery/valve/New()
	..()
	gas1 = new/obj/substance/gas(src)
	ngas1 = new/obj/substance/gas()
	gas2 = new/obj/substance/gas(src)
	ngas2 = new/obj/substance/gas()

	gasflowlist += src
	switch(dir)
		if(1, 2)
			p_dir = 3
		if(4,8)
			p_dir = 12

	icon_state = "valve[open]"

/obj/machinery/valve/examine()
	set src in oview(1)

	usr << "[desc] It is [ open? "open" : "closed"]."



/obj/machinery/valve/buildnodes()

	var/turf/T = src.loc

	node1 = get_machine(level, T, dir )		// the h/e pipe

	node2 = get_machine(level, T , turn(dir, 180) )	// the regular pipe

	if(node1) vnode1 = node1.getline()
	if(node2) vnode2 = node2.getline()

	return


/obj/machinery/valve/gas_flow()

	gas1.replace_by(ngas1)
	gas2.replace_by(ngas2)


/obj/machinery/valve/process()


	var/delta_gt

	if(vnode1)
		delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas1.tot_gas() / capmult)
		calc_delta( src, gas1, ngas1, vnode1, delta_gt)

	else
		leak_to_turf(1)

	if(vnode2)
		delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas2.tot_gas() / capmult)
		calc_delta( src, gas2, ngas2, vnode2, delta_gt)

	else
		leak_to_turf(2)


	if(open)		// valve operating, so transfer btwen resv1 & 2

		delta_gt = FLOWFRAC * (gas1.tot_gas() / capmult - gas2.tot_gas() / capmult)

		var/obj/substance/gas/ndelta = new()

		if(delta_gt < 0)		// then flowing from R2 to R1

			ndelta.set_frac(gas2, -delta_gt)

			ngas2.sub_delta(ndelta)
			ngas1.add_delta(ndelta)

		else				// flowing from R1 to R2
			ndelta.set_frac(gas1, delta_gt)
			ngas2.add_delta(ndelta)
			ngas1.sub_delta(ndelta)




/obj/machinery/valve/get_gas_val(from)
	if(from == vnode2)
		return gas2.tot_gas()/capmult
	else
		return gas1.tot_gas()/capmult

/obj/machinery/valve/get_gas(from)
	if(from == vnode2)
		return gas2
	return gas1

/obj/machinery/valve/proc/leak_to_turf(var/port)

	var/turf/T


	switch(port)
		if(1)
			T = get_step(src, dir)
		if(2)
			T = get_step(src, turn(dir, 180) )

	if(T.density)
		T = src.loc
		if(T.density)
			return

	if(port==1)
		flow_to_turf(gas1, ngas1, T)
	else
		flow_to_turf(gas2, ngas2, T)

/obj/machinery/valve/attack_paw(mob/user)
	attack_hand(user)

/obj/machinery/valve/attack_hand(mob/user)
	..()
	add_fingerprint(user)
//	if(stat & NOPOWER) return

//	use_power(5)

	if(!open)		// now opening
		flick("valve01", src)
		icon_state = "valve1"
		sleep(10)
	else			// now closing
		flick("valve10", src)
		icon_state = "valve0"
		sleep(10)
	open = !open

