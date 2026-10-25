AFTER HOURS - Mess & Student Model Upgrade

INSTALL:
  1. Back up your existing res://world/world.tscn
  2. Copy the entire contents of this world/ folder into your PROJECT's res://world/ folder
     (copy the assets/models subfolder and avatar_hide_capsule.gd; do not copy only world.tscn).
  3. Allow Godot to import the .glb student models before pressing F6.
  4. Keep your existing player.tscn, player.gd, world.gd, camera_follow.gd,
     and world_boundaries.gd. They are not included or overwritten.

The 3D student models are original procedural stylized low-poly GLB assets,
created for this project. No third-party assets or fonts are included.
They are static display meshes, not skeletal animated/rigger characters.
Player movement/collision and all NPC collision bodies remain intact.

Five NPCs (roommate plus four bucket-fight students) and the player
receive visually detailed bodies with clothing, hair, face and shoes.
The player avatar is added to the World instance and its old capsule
is hidden at runtime by avatar_hide_capsule.gd.

Test study/eat/sleep/socialize/bucket_fight/lawn_walk/badminton and
camera & collisions before merging into main branch.
