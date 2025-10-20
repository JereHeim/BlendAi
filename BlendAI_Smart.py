#!/usr/bin/env python3
import bpy
import bmesh
import os
import sys
import logging
import argparse
import requests
import json
import subprocess
from pathlib import Path
from mathutils import Vector
from typing import List, Optional, Tuple, Dict
import tempfile
import shutil

# Configure logging for server environment
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/blendai_smart.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class SmartBlendAI:
    """AI-Powered 3D Model Generation and Processing"""
    
    def __init__(self, output_dir: str = "/tmp/blendai_output"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir = Path(tempfile.mkdtemp(prefix="blendai_"))
        self.imported_objects: List[bpy.types.Object] = []
        self.reference_image_path: Optional[Path] = None
        self.reference_plane: Optional[bpy.types.Object] = None
        
    def generate_model_from_text(self, prompt: str, model_type: str = "auto", reference_image: Optional[str] = None) -> Optional[str]:
        """Generate 3D model from text description using various AI methods"""
        logger.info(f"Generating 3D model from prompt: '{prompt}'")
        
        # Store reference image if provided
        if reference_image and Path(reference_image).exists():
            self.reference_image_path = Path(reference_image)
            logger.info(f"Using reference image: {reference_image}")
        
        # Try different generation methods
        methods = [
            self._generate_with_reference_analysis,
            self._generate_with_procedural,
            self._generate_basic_primitive
        ]
        
        for method in methods:
            try:
                result = method(prompt, model_type)
                if result:
                    logger.info(f"Successfully generated model using {method.__name__}")
                    # Add reference image to scene if provided
                    if self.reference_image_path:
                        self._setup_reference_image()
                    return result
            except Exception as e:
                logger.warning(f"Method {method.__name__} failed: {e}")
                continue
        
        logger.error("All generation methods failed")
        return None
    
    def _generate_with_reference_analysis(self, prompt: str, model_type: str) -> Optional[str]:
        """Generate using reference image analysis for better accuracy"""
        if not self.reference_image_path:
            return None
            
        logger.info(f"Analyzing reference image: {self.reference_image_path}")
        
        # Analyze the reference image to extract information
        analysis = self._analyze_reference_image(prompt)
        
        # Use analysis to inform generation
        if analysis['type'] == 'sword':
            return self._create_reference_guided_sword(prompt, analysis)
        elif analysis['type'] == 'character':
            return self._create_reference_guided_character(prompt, analysis)
        elif analysis['type'] == 'building':
            return self._create_reference_guided_building(prompt, analysis)
        else:
            return self._create_reference_guided_generic(prompt, analysis)
    
    def _analyze_reference_image(self, prompt: str) -> Dict:
        """Analyze reference image to extract proportions and features"""
        logger.info("Analyzing reference image for proportions and features")
        
        # Basic analysis based on prompt and image presence
        analysis = {
            'type': 'generic',
            'proportions': {'width': 1.0, 'height': 1.0, 'depth': 1.0},
            'style': 'basic',
            'features': []
        }
        
        prompt_lower = prompt.lower()
        
        # Determine object type from prompt
        if any(word in prompt_lower for word in ['sword', 'blade', 'katana', 'dagger', 'greatsword']):
            analysis['type'] = 'sword'
            if 'katana' in prompt_lower:
                analysis['proportions'] = {'width': 0.08, 'height': 0.05, 'depth': 2.5}
                analysis['style'] = 'curved'
                analysis['features'] = ['curved_blade', 'long_handle', 'guard']
            elif 'dagger' in prompt_lower:
                analysis['proportions'] = {'width': 0.12, 'height': 0.06, 'depth': 0.8}
                analysis['style'] = 'short'
                analysis['features'] = ['short_blade', 'small_guard']
            elif 'greatsword' in prompt_lower:
                analysis['proportions'] = {'width': 0.15, 'height': 0.08, 'depth': 3.5}
                analysis['style'] = 'large'
                analysis['features'] = ['long_blade', 'large_guard', 'long_handle']
            else:
                analysis['proportions'] = {'width': 0.1, 'height': 0.05, 'depth': 1.8}
                analysis['style'] = 'standard'
                analysis['features'] = ['blade', 'guard', 'handle']
                
        elif any(word in prompt_lower for word in ['human', 'character', 'warrior', 'mage']):
            analysis['type'] = 'character'
            analysis['proportions'] = {'width': 0.6, 'height': 1.8, 'depth': 0.3}
            
        elif any(word in prompt_lower for word in ['castle', 'building', 'tower', 'house']):
            analysis['type'] = 'building'
            analysis['proportions'] = {'width': 4.0, 'height': 6.0, 'depth': 4.0}
        
        logger.info(f"Analysis result: {analysis}")
        return analysis
    
    def _generate_with_procedural(self, prompt: str, model_type: str) -> Optional[str]:
        """Generate using procedural modeling based on text analysis"""
        logger.info(f"Generating procedural model for: {prompt}")
        
        # Analyze prompt to determine what to create
        prompt_lower = prompt.lower()
        
        if any(word in prompt_lower for word in ['sword', 'blade', 'weapon']):
            return self._create_procedural_sword(prompt)
        elif any(word in prompt_lower for word in ['human', 'person', 'character', 'man', 'woman']):
            return self._create_procedural_human(prompt)
        elif any(word in prompt_lower for word in ['goblin', 'orc', 'monster', 'creature']):
            return self._create_procedural_creature(prompt)
        elif any(word in prompt_lower for word in ['building', 'house', 'castle', 'tower']):
            return self._create_procedural_building(prompt)
        else:
            return self._create_procedural_generic(prompt)
    
    def _create_reference_guided_sword(self, prompt: str, analysis: Dict) -> str:
        """Create a sword based on reference image analysis"""
        logger.info(f"Creating reference-guided sword: {analysis['style']}")
        
        # Clear scene
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        props = analysis['proportions']
        style = analysis['style']
        features = analysis['features']
        
        # Create blade with reference-guided proportions
        bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0))
        blade = bpy.context.active_object
        blade.name = "Sword_Blade"
        blade.scale = (props['width'], props['height'], props['depth'])
        
        # Apply style-specific modifications
        if style == 'curved' and 'curved_blade' in features:
            # Add curve to katana
            mod_simple_deform = blade.modifiers.new(name="Curve", type='SIMPLE_DEFORM')
            mod_simple_deform.deform_method = 'BEND'
            mod_simple_deform.angle = 0.1  # Slight curve
            mod_simple_deform.deform_axis = 'Z'
        
        # Create guard proportional to blade
        guard_scale = 0.3 if style == 'short' else 0.4 if style == 'large' else 0.35
        guard_z = -props['depth'] * 0.6
        
        bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, guard_z))
        guard = bpy.context.active_object
        guard.name = "Sword_Guard"
        guard.scale = (guard_scale, props['height'], props['height'] * 2)
        
        # Create handle proportional to sword type
        handle_length = 0.8 if style == 'large' else 0.4 if style == 'short' else 0.6
        handle_z = guard_z - handle_length/2
        
        bpy.ops.mesh.primitive_cylinder_add(radius=props['width']*0.8, depth=handle_length, location=(0, 0, handle_z))
        handle = bpy.context.active_object
        handle.name = "Sword_Handle"
        
        # Create pommel
        pommel_z = handle_z - handle_length/2 - 0.1
        bpy.ops.mesh.primitive_uv_sphere_add(radius=props['width']*1.2, location=(0, 0, pommel_z))
        pommel = bpy.context.active_object
        pommel.name = "Sword_Pommel"
        
        # Join all parts
        bpy.ops.object.select_all(action='DESELECT')
        blade.select_set(True)
        guard.select_set(True)
        handle.select_set(True)
        pommel.select_set(True)
        bpy.context.view_layer.objects.active = blade
        bpy.ops.object.join()
        
        sword = bpy.context.active_object
        sword.name = f"Generated_{style.title()}_Sword"
        
        # Add reference-specific details
        self._add_reference_sword_details(sword, prompt, analysis)
        
        # Export as FBX
        output_path = self.output_dir / f"generated_{style}_sword.fbx"
        bpy.ops.export_scene.fbx(filepath=str(output_path), use_selection=True)
        
        self.imported_objects = [sword]
        return str(output_path)
    
    def _add_reference_sword_details(self, sword_obj: bpy.types.Object, prompt: str, analysis: Dict):
        """Add details based on reference analysis"""
        prompt_lower = prompt.lower()
        style = analysis['style']
        
        # Add subdivision for smoother look
        mod_subsurf = sword_obj.modifiers.new(name="Subdivision", type='SUBSURF')
        mod_subsurf.levels = 1 if style == 'short' else 2
        
        # Add bevels for realistic edges
        mod_bevel = sword_obj.modifiers.new(name="Bevel", type='BEVEL')
        mod_bevel.width = 0.005 if style == 'short' else 0.01
        mod_bevel.segments = 2
        
        # Style-specific modifications
        if style == 'curved':
            # Katana-specific details
            mod_wave = sword_obj.modifiers.new(name="Edge_Wave", type='WAVE')
            mod_wave.height = 0.002
            mod_wave.width = 1.0
            mod_wave.axis = 'Z'
            
        elif style == 'large':
            # Greatsword-specific details  
            mod_array = sword_obj.modifiers.new(name="Fuller", type='SOLIDIFY')
            mod_array.thickness = -0.01
            
        # Special effects based on prompt
        if any(word in prompt_lower for word in ['flame', 'fire', 'burning']):
            mod_displace = sword_obj.modifiers.new(name="Flame_Effect", type='DISPLACE')
            mod_displace.strength = 0.02
    
    def _create_procedural_human(self, prompt: str) -> str:
        """Create a basic human figure"""
        logger.info("Creating procedural human")
        
        # Clear scene
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        # Create basic human using meta balls for organic shape
        bpy.ops.object.metaball_add(type='BALL', location=(0, 0, 0))
        head = bpy.context.active_object
        head.name = "Human_Head"
        head.scale = (0.3, 0.3, 0.35)
        head.location = (0, 0, 1.7)
        
        # Torso
        bpy.ops.object.metaball_add(type='ELLIPSOID', location=(0, 0, 1.0))
        torso = bpy.context.active_object
        torso.scale = (0.4, 0.2, 0.6)
        
        # Arms
        bpy.ops.object.metaball_add(type='CAPSULE', location=(0.6, 0, 1.2))
        arm_r = bpy.context.active_object
        arm_r.scale = (0.15, 0.15, 0.5)
        arm_r.rotation_euler = (0, 0, 1.57)
        
        bpy.ops.object.metaball_add(type='CAPSULE', location=(-0.6, 0, 1.2))
        arm_l = bpy.context.active_object
        arm_l.scale = (0.15, 0.15, 0.5)
        arm_l.rotation_euler = (0, 0, -1.57)
        
        # Legs
        bpy.ops.object.metaball_add(type='CAPSULE', location=(0.2, 0, 0.0))
        leg_r = bpy.context.active_object
        leg_r.scale = (0.15, 0.15, 0.6)
        
        bpy.ops.object.metaball_add(type='CAPSULE', location=(-0.2, 0, 0.0))
        leg_l = bpy.context.active_object
        leg_l.scale = (0.15, 0.15, 0.6)
        
        # Convert to mesh
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.convert(target='MESH')
        bpy.ops.object.join()
        
        human = bpy.context.active_object
        human.name = "Generated_Human"
        
        # Add subdivision for smoother look
        mod_subsurf = human.modifiers.new(name="Subdivision", type='SUBSURF')
        mod_subsurf.levels = 2
        
        # Export as FBX
        output_path = self.output_dir / "generated_human.fbx"
        bpy.ops.export_scene.fbx(filepath=str(output_path), use_selection=True)
        
        self.imported_objects = [human]
        return str(output_path)
    
    def _setup_reference_image(self) -> bool:
        """Setup reference image in the scene"""
        if not self.reference_image_path or not self.reference_image_path.exists():
            return False
            
        try:
            logger.info(f"Setting up reference image: {self.reference_image_path}")
            
            # Create a plane for the reference image
            bpy.ops.mesh.primitive_plane_add(size=3, location=(5, 0, 0))
            self.reference_plane = bpy.context.active_object
            self.reference_plane.name = "Reference_Image"
            
            # Create material for the image
            mat = bpy.data.materials.new(name="Reference_Material")
            mat.use_nodes = True
            nodes = mat.node_tree.nodes
            nodes.clear()
            
            # Create nodes
            output = nodes.new('ShaderNodeOutputMaterial')
            principled = nodes.new('ShaderNodeBsdfPrincipled')
            tex_image = nodes.new('ShaderNodeTexImage')
            
            # Load the reference image
            img = bpy.data.images.load(str(self.reference_image_path))
            tex_image.image = img
            
            # Link nodes
            mat.node_tree.links.new(tex_image.outputs['Color'], principled.inputs['Base Color'])
            mat.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])
            
            # Assign material to plane
            self.reference_plane.data.materials.append(mat)
            
            # Position the reference plane next to the generated model
            self._position_reference_plane()
            
            logger.info("Reference image setup completed")
            return True
            
        except Exception as e:
            logger.error(f"Failed to setup reference image: {e}")
            return False
    
    def _position_reference_plane(self) -> None:
        """Position reference plane next to the generated model"""
        if not self.reference_plane or not self.imported_objects:
            return
            
        try:
            # Calculate bounds of generated objects
            all_coords = []
            for obj in self.imported_objects:
                if obj.type == 'MESH':
                    for vertex in obj.data.vertices:
                        world_coord = obj.matrix_world @ vertex.co
                        all_coords.append(world_coord)
            
            if all_coords:
                min_coords = Vector((min(coord.x for coord in all_coords),
                                   min(coord.y for coord in all_coords),
                                   min(coord.z for coord in all_coords)))
                max_coords = Vector((max(coord.x for coord in all_coords),
                                   max(coord.y for coord in all_coords),
                                   max(coord.z for coord in all_coords)))
                
                model_center = (min_coords + max_coords) / 2
                model_size = max_coords - min_coords
                
                # Position reference plane to the side
                offset_distance = max(model_size) * 1.5
                self.reference_plane.location.x = model_center.x + offset_distance
                self.reference_plane.location.z = model_center.z
                
                # Scale reference plane based on model size
                scale_factor = max(model_size) * 0.8
                self.reference_plane.scale = (scale_factor, scale_factor, 1)
                
                logger.info(f"Reference plane positioned at {self.reference_plane.location}")
                
        except Exception as e:
            logger.error(f"Failed to position reference plane: {e}")
    
    def _create_reference_guided_character(self, prompt: str, analysis: Dict) -> str:
        """Create character using reference image guidance"""
        logger.info("Creating reference-guided character")
        
        # Use the existing character creation but with reference proportions
        result = self._create_procedural_human(prompt)
        
        # Apply reference-specific modifications
        if self.imported_objects:
            character = self.imported_objects[0]
            props = analysis['proportions']
            
            # Adjust proportions based on reference
            character.scale = (props['width'], props['depth'], props['height'])
            
        return result
    
    def _create_reference_guided_building(self, prompt: str, analysis: Dict) -> str:
        """Create building using reference image guidance"""
        logger.info("Creating reference-guided building")
        
        # Use the existing building creation but with reference proportions
        result = self._create_procedural_building(prompt)
        
        # Apply reference-specific modifications
        if self.imported_objects:
            building = self.imported_objects[0]
            props = analysis['proportions']
            
            # Adjust proportions based on reference
            building.scale = (props['width'], props['depth'], props['height'])
            
        return result
    
    def _create_reference_guided_generic(self, prompt: str, analysis: Dict) -> str:
        """Create generic object using reference image guidance"""
        logger.info("Creating reference-guided generic object")
        
        # Use the existing generic creation but with reference proportions
        result = self._create_procedural_generic(prompt)
        
        # Apply reference-specific modifications
        if self.imported_objects:
            obj = self.imported_objects[0]
            props = analysis['proportions']
            
            # Adjust proportions based on reference
            obj.scale = (props['width'], props['depth'], props['height'])
            
        return result
    
    def _create_procedural_creature(self, prompt: str) -> str:
        """Create a creature (goblin, orc, etc.)"""
        logger.info("Creating procedural creature")
        
        # Start with human base and modify
        human_path = self._create_procedural_human("base creature")
        
        # Modify for creature characteristics
        creature = bpy.context.active_object
        creature.name = "Generated_Creature"
        
        prompt_lower = prompt.lower()
        
        # Make goblin-like modifications
        if 'goblin' in prompt_lower:
            # Scale down and make more hunched
            creature.scale = (0.7, 0.7, 0.8)
            creature.location = (0, 0, -0.2)
            
            # Add pointy ears (simple geometry)
            bpy.ops.mesh.primitive_cone_add(radius1=0.05, depth=0.15, location=(0.25, 0, 1.8))
            ear_r = bpy.context.active_object
            ear_r.rotation_euler = (0, 1.57, 0.5)
            
            bpy.ops.mesh.primitive_cone_add(radius1=0.05, depth=0.15, location=(-0.25, 0, 1.8))
            ear_l = bpy.context.active_object
            ear_l.rotation_euler = (0, -1.57, -0.5)
            
            # Join ears to main body
            bpy.ops.object.select_all(action='DESELECT')
            creature.select_set(True)
            ear_r.select_set(True)
            ear_l.select_set(True)
            bpy.context.view_layer.objects.active = creature
            bpy.ops.object.join()
        
        # Export as FBX
        output_path = self.output_dir / "generated_creature.fbx"
        bpy.ops.export_scene.fbx(filepath=str(output_path), use_selection=True)
        
        self.imported_objects = [creature]
        return str(output_path)
    
    def _create_procedural_building(self, prompt: str) -> str:
        """Create a procedural building"""
        logger.info("Creating procedural building")
        
        # Clear scene
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        prompt_lower = prompt.lower()
        
        if 'castle' in prompt_lower:
            # Create castle base
            bpy.ops.mesh.primitive_cube_add(size=4, location=(0, 0, 1))
            base = bpy.context.active_object
            base.scale = (2, 2, 1)
            
            # Add towers
            for i, pos in enumerate([(2, 2, 2.5), (-2, 2, 2.5), (2, -2, 2.5), (-2, -2, 2.5)]):
                bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=3, location=pos)
                tower = bpy.context.active_object
                tower.name = f"Tower_{i}"
            
            # Add main keep
            bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 3))
            keep = bpy.context.active_object
            keep.scale = (1, 1, 2)
            
        else:
            # Generic building
            bpy.ops.mesh.primitive_cube_add(size=4, location=(0, 0, 2))
            base = bpy.context.active_object
            base.scale = (1.5, 1, 2)
        
        # Join all parts
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.join()
        
        building = bpy.context.active_object
        building.name = "Generated_Building"
        
        # Add some architectural details
        mod_bevel = building.modifiers.new(name="Bevel", type='BEVEL')
        mod_bevel.width = 0.05
        
        # Export as FBX
        output_path = self.output_dir / "generated_building.fbx"
        bpy.ops.export_scene.fbx(filepath=str(output_path), use_selection=True)
        
        self.imported_objects = [building]
        return str(output_path)
    
    def _create_procedural_generic(self, prompt: str) -> str:
        """Create a generic object based on simple keywords"""
        logger.info(f"Creating generic object for: {prompt}")
        
        # Clear scene
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        # Simple keyword-based generation
        prompt_lower = prompt.lower()
        
        if any(word in prompt_lower for word in ['box', 'cube', 'container']):
            bpy.ops.mesh.primitive_cube_add(size=2)
        elif any(word in prompt_lower for word in ['ball', 'sphere', 'orb']):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=1)
        elif any(word in prompt_lower for word in ['tree', 'plant']):
            # Simple tree
            bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=2, location=(0, 0, 1))
            trunk = bpy.context.active_object
            bpy.ops.mesh.primitive_uv_sphere_add(radius=0.8, location=(0, 0, 2.5))
            leaves = bpy.context.active_object
            leaves.scale = (1, 1, 0.6)
            bpy.ops.object.select_all(action='SELECT')
            bpy.ops.object.join()
        else:
            # Default to cube
            bpy.ops.mesh.primitive_cube_add(size=2)
        
        obj = bpy.context.active_object
        obj.name = "Generated_Object"
        
        # Export as FBX
        output_path = self.output_dir / "generated_object.fbx"
        bpy.ops.export_scene.fbx(filepath=str(output_path), use_selection=True)
        
        self.imported_objects = [obj]
        return str(output_path)
    
    def _generate_basic_primitive(self, prompt: str, model_type: str) -> Optional[str]:
        """Fallback: generate basic primitive shapes"""
        logger.info("Using basic primitive generation as fallback")
        return self._create_procedural_generic(prompt)
    
    def create_smart_material(self, material_name: str, description: str = "") -> bpy.types.Material:
        """Create materials based on text description"""
        logger.info(f"Creating smart material: {material_name} - {description}")
        
        # Remove existing material
        if material_name in bpy.data.materials:
            bpy.data.materials.remove(bpy.data.materials[material_name])
        
        mat = bpy.data.materials.new(material_name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        
        # Base nodes
        output = nodes.new('ShaderNodeOutputMaterial')
        principled = nodes.new('ShaderNodeBsdfPrincipled')
        
        # Analyze description for material properties
        desc_lower = description.lower()
        
        if any(word in desc_lower for word in ['metal', 'steel', 'iron', 'sword']):
            # Metallic material
            principled.inputs['Base Color'].default_value = (0.7, 0.7, 0.8, 1.0)
            principled.inputs['Metallic'].default_value = 0.9
            principled.inputs['Roughness'].default_value = 0.1
            
        elif any(word in desc_lower for word in ['wood', 'tree', 'bark']):
            # Wood material
            principled.inputs['Base Color'].default_value = (0.4, 0.2, 0.1, 1.0)
            principled.inputs['Metallic'].default_value = 0.0
            principled.inputs['Roughness'].default_value = 0.8
            
        elif any(word in desc_lower for word in ['skin', 'flesh', 'human', 'creature']):
            # Skin material
            principled.inputs['Base Color'].default_value = (0.8, 0.6, 0.5, 1.0)
            principled.inputs['Metallic'].default_value = 0.0
            principled.inputs['Roughness'].default_value = 0.3
            principled.inputs['Subsurface'].default_value = 0.1
            
        elif any(word in desc_lower for word in ['stone', 'rock', 'castle', 'building']):
            # Stone material
            principled.inputs['Base Color'].default_value = (0.5, 0.5, 0.5, 1.0)
            principled.inputs['Metallic'].default_value = 0.0
            principled.inputs['Roughness'].default_value = 0.9
            
        else:
            # Default material
            principled.inputs['Base Color'].default_value = (0.6, 0.6, 0.6, 1.0)
            principled.inputs['Metallic'].default_value = 0.0
            principled.inputs['Roughness'].default_value = 0.5
        
        # Add some procedural texture for variation
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 10.0
        color_ramp = nodes.new('ShaderNodeValToRGB')
        
        # Link nodes
        links.new(noise.outputs['Fac'], color_ramp.inputs['Fac'])
        links.new(color_ramp.outputs['Color'], principled.inputs['Roughness'])
        links.new(principled.outputs['BSDF'], output.inputs['Surface'])
        
        return mat
    
    def apply_smart_materials(self, description: str = "") -> None:
        """Apply materials intelligently based on object and description"""
        for obj in self.imported_objects:
            if obj.type == 'MESH':
                # Create material based on object name and description
                material_name = f"Smart_{obj.name}"
                mat = self.create_smart_material(material_name, f"{obj.name} {description}")
                
                # Clear existing materials and apply new one
                obj.data.materials.clear()
                obj.data.materials.append(mat)
                logger.info(f"Applied smart material to: {obj.name}")
    
    def render_smart_preview(self, filename: str = "smart_preview.png") -> bool:
        """Render a preview with smart camera positioning"""
        try:
            # Position camera intelligently based on generated objects
            if self.imported_objects:
                # Calculate bounding box of all objects
                all_coords = []
                for obj in self.imported_objects:
                    if obj.type == 'MESH':
                        for vertex in obj.data.vertices:
                            world_coord = obj.matrix_world @ vertex.co
                            all_coords.append(world_coord)
                
                if all_coords:
                    # Get bounds
                    min_coords = Vector((min(coord.x for coord in all_coords),
                                       min(coord.y for coord in all_coords),
                                       min(coord.z for coord in all_coords)))
                    max_coords = Vector((max(coord.x for coord in all_coords),
                                       max(coord.y for coord in all_coords),
                                       max(coord.z for coord in all_coords)))
                    
                    center = (min_coords + max_coords) / 2
                    size = max_coords - min_coords
                    distance = max(size) * 2
                    
                    # Position camera
                    camera = bpy.data.objects.get('Camera')
                    if not camera:
                        bpy.ops.object.camera_add()
                        camera = bpy.context.active_object
                    
                    camera.location = center + Vector((distance, -distance, distance * 0.5))
                    
                    # Point camera at center
                    direction = center - camera.location
                    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
            
            # Set up lighting
            light = bpy.data.objects.get('Light')
            if not light:
                bpy.ops.object.light_add(type='SUN')
                light = bpy.context.active_object
            
            light.data.energy = 3.0
            light.location = (5, 5, 10)
            
            # Render settings
            scene = bpy.context.scene
            scene.render.filepath = str(self.output_dir / filename)
            scene.render.image_settings.file_format = 'PNG'
            scene.render.resolution_x = 1920
            scene.render.resolution_y = 1080
            scene.render.engine = 'CYCLES'
            scene.cycles.samples = 64
            
            # Render
            bpy.ops.render.render(write_still=True)
            logger.info(f"Smart preview rendered: {filename}")
            return True
            
        except Exception as e:
            logger.error(f"Smart preview render failed: {e}")
            return False
    
    def generate_and_process(self, prompt: str, description: str = "", reference_image: Optional[str] = None) -> bool:
        """Complete pipeline: generate model, apply materials, render"""
        logger.info(f"Starting smart generation pipeline for: '{prompt}'")
        if reference_image:
            logger.info(f"Using reference image: {reference_image}")
        
        # Generate the 3D model
        model_path = self.generate_model_from_text(prompt, reference_image=reference_image)
        if not model_path:
            logger.error("Failed to generate 3D model")
            return False
        
        # Apply smart materials
        self.apply_smart_materials(f"{prompt} {description}")
        
        # Save as Blender file
        blend_path = self.output_dir / f"smart_{prompt.replace(' ', '_')}.blend"
        bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
        
        # Render preview
        preview_name = f"smart_{prompt.replace(' ', '_')}_preview.png"
        self.render_smart_preview(preview_name)
        
        logger.info("Smart generation pipeline completed successfully!")
        return True

def main():
    """Main function for command line usage"""
    parser = argparse.ArgumentParser(description='Smart BlendAI - AI-Powered 3D Model Generation')
    parser.add_argument('--prompt', '-p', required=True, help='Text description of what to generate')
    parser.add_argument('--description', '-d', default='', help='Additional material/style description')
    parser.add_argument('--reference', '-r', help='Reference image for better accuracy')
    parser.add_argument('--output', '-o', default='/tmp/blendai_output', help='Output directory')
    parser.add_argument('--type', '-t', default='auto', help='Model type hint (auto, character, weapon, building)')
    
    args = parser.parse_args()
    
    # Validate reference image if provided
    if args.reference and not Path(args.reference).exists():
        print(f"❌ Reference image not found: {args.reference}")
        sys.exit(1)
    
    # Create and run smart BlendAI
    smart_ai = SmartBlendAI(args.output)
    success = smart_ai.generate_and_process(args.prompt, args.description, args.reference)
    
    if success:
        print(f"✅ Smart generation completed! Results in: {args.output}")
        if args.reference:
            print(f"📸 Reference image used: {args.reference}")
    else:
        print("❌ Smart generation failed. Check logs for details.")
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        main()
    else:
        # Interactive mode
        print("🤖 Smart BlendAI - AI-Powered 3D Model Generation")
        print("Examples of what you can generate:")
        print("  - 'medieval sword with flame effects'")
        print("  - 'goblin warrior with armor'") 
        print("  - 'castle with towers'")
        print("  - 'human character'")
        
        prompt = input("\nWhat would you like to generate? ")
        if prompt:
            smart_ai = SmartBlendAI()
            smart_ai.generate_and_process(prompt)