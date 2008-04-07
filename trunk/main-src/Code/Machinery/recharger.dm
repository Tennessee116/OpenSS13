/**
 * Recharger -- A recharger is a piece of Machinery that re-supplys tazers and lazers.
 *
 * TODO: Need seriously improved documentation on this object. Most of the procs and
 *       variables seem to live elsewhere, need a project decision on how these cases
 *       get documented and referenced.
 */
obj
	machinery
		recharger
			anchored = 1.0
			icon = 'stationobjs.dmi'
			icon_state = "recharger0"
			name = "recharger"
		
			var
				obj/item/weapon/gun/energy/charging = null
		
			attackby(obj/item/weapon/G as obj, mob/user as mob)
				if (src.charging)
					return
				if (istype(G, /obj/item/weapon/gun/energy))
					user.drop_item()
					G.loc = src
					src.charging = G

			attack_hand(mob/user as mob)
				src.add_fingerprint(user)
				if (src.charging)
					src.charging.update_icon()
					src.charging.loc = src.loc
					src.charging = null

			attack_paw(mob/user as mob)
				if ((ticker && ticker.mode == "monkey"))
					return src.attack_hand(user)

			process()
				if (src.charging && ! (stat & NOPOWER) )
					if (src.charging.charges < 10)
						src.charging.charges++
						src.icon_state = "recharger1"
						use_power(250)
					else
						src.icon_state = "recharger2"
				else
					src.icon_state = "recharger0"
