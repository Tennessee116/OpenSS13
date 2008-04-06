/obj/item/weapon/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = "t-scanner[on]"

	if(on)
		src.process()


/obj/item/weapon/t_scanner/proc/process()

	while(on)
		for(var/turf/T in range(1, src.loc) )

			if(!T.intact)
				continue

			for(var/obj/O in T.contents)

				if(O.level != 1)
					continue

				if(O.invisibility == 101)
					O.invisibility = 0
					spawn(10)
						if(O)
							var/turf/U = O.loc
							if(U.intact)
								O.invisibility = 101

			var/mob/human/M = locate() in T
			if(M && M.invisibility == 2)
				M.invisibility = 0
				spawn(2)
					if(M)
						M.invisibility = 2


		sleep(10)

/obj/item/weapon/flashlight/attack_self(mob/user)

	on = !on
	icon_state = "flight[on]"

	if(on)
		img = image('turfs2.dmi', "light", 11)
		user:body_standing += img
	else
		if(img)
			user:body_standing -= img
			del(img)



///obj/item/weapon/flashlight/dropped()
//	on = 0


