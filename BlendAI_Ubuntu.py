#!/usr/bin/env python3
import bpy
import bmesh
import os
import sys
import logging
import argparse
from pathlib import Path
from mathutils import Vector
from typing import List, Optional, Tuple

# Configure logging for server environment
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/blendai.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class BlendAISetup:
    """Smart Blender setup class for character model workflow - Ubuntu Server Compatible"""
    
    def __init__(self, base_model_path: str, reference_image_path: str, output_dir: str = "/tmp/blendai_output"):
        self.base_model_path = Path(base_model_path)
        self.reference_image_path = Path(reference_image_path)
        self.output_dir = Path(output_dir)
        self.imported_objects: List[bpy.types.Object] = []
        self.reference_plane: Optional[bpy.types.Object] = None
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def validate_files(self) -> bool:
        """Validate that required files exist"""
        if not self.base_model_path.exists():
            logger.error(f"Base model not found: {self.base_model_path}")
            return False
        if not self.reference_image_path.exists():
            logger.error(f"Reference image not found: {self.reference_image_path}")
            return False
        logger.info("All files validated successfully")
        return True
    
    def clear_scene(self, keep_camera_light: bool = True) -> None:
        """Smart scene cleanup, optionally keeping camera and light"""
        if keep_camera_light:
            objects_to_delete = [obj for obj in bpy.context.scene.objects 
                               if obj.type not in ['CAMERA', 'LIGHT']]
        else:
            objects_to_delete = list(bpy.context.scene.objects)
        
        # Use bmesh for efficient deletion
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects_to_delete:
            obj.select_set(True)
        bpy.ops.object.delete()
        logger.info(f"Cleared {len(objects_to_delete)} objects from scene")
    
    def import_model(self) -> bool:
        """Import FBX model with error handling"""
        try:
            # Store objects before import to identify new ones
            objects_before = set(bpy.context.scene.objects)
            
            bpy.ops.import_scene.fbx(filepath=str(self.base_model_path))
            
            # Find newly imported objects
            objects_after = set(bpy.context.scene.objects)
            self.imported_objects = list(objects_after - objects_before)
            
            if not self.imported_objects:
                logger.error("No objects were imported from FBX file")
                return False
                
            logger.info(f"Successfully imported {len(self.imported_objects)} objects")
            return True
            
        except Exception as e:
            logger.error(f"Failed to import model: {e}")
            return False
    
    def setup_reference_image(self) -> bool:
        """Import and position reference image intelligently"""
        try:
            # Check if addon is available (might not be in headless mode)
            if 'import_image' not in dir(bpy.ops):
                logger.warning("Import Images as Planes addon not available in headless mode")
                return self._create_reference_plane_manually()
            
            objects_before = set(bpy.context.scene.objects)
            
            bpy.ops.import_image.to_plane(
                files=[{"name": self.reference_image_path.name}],
                directory=str(self.reference_image_path.parent),
                align_axis='Z+',
                size_mode='CAMERA'
            )
            
            # Find the reference plane
            objects_after = set(bpy.context.scene.objects)
            new_objects = list(objects_after - objects_before)
            
            if new_objects:
                self.reference_plane = new_objects[0]
                # Position reference plane smartly based on model bounds
                self._position_reference_plane()
                logger.info("Reference image imported and positioned")
                return True
            else:
                logger.error("Failed to import reference image")
                return False
                
        except Exception as e:
            logger.error(f"Failed to setup reference image: {e}")
            return self._create_reference_plane_manually()
    
    def _create_reference_plane_manually(self) -> bool:
        """Create reference plane manually when addon is not available"""
        try:
            # Create a plane
            bpy.ops.mesh.primitive_plane_add(size=2, location=(0, 0, 0))
            self.reference_plane = bpy.context.active_object
            self.reference_plane.name = "Reference_Plane"
            
            # Create material and load image
            mat = bpy.data.materials.new(name="Reference_Material")
            mat.use_nodes = True
            nodes = mat.node_tree.nodes
            
            # Clear default nodes
            nodes.clear()
            
            # Add nodes
            output = nodes.new('ShaderNodeOutputMaterial')
            principled = nodes.new('ShaderNodeBsdfPrincipled')
            tex_image = nodes.new('ShaderNodeTexImage')
            
            # Load image
            img = bpy.data.images.load(str(self.reference_image_path))
            tex_image.image = img
            
            # Link nodes
            mat.node_tree.links.new(tex_image.outputs['Color'], principled.inputs['Base Color'])
            mat.node_tree.links.new(principled.outputs['BSDF'], output.inputs['Surface'])
            
            # Assign material
            self.reference_plane.data.materials.append(mat)
            
            # Position the plane
            self._position_reference_plane()
            
            logger.info("Reference plane created manually")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create reference plane manually: {e}")
            return False
    
    def _position_reference_plane(self) -> None:
        """Position reference plane based on imported model bounds"""
        if not self.imported_objects or not self.reference_plane:
            return
        
        # Calculate bounding box of all imported objects
        all_coords = []
        for obj in self.imported_objects:
            if obj.type == 'MESH':
                for vertex in obj.data.vertices:
                    world_coord = obj.matrix_world @ vertex.co
                    all_coords.append(world_coord)
        
        if all_coords:
            # Get model dimensions
            min_coords = Vector((min(coord.x for coord in all_coords),
                               min(coord.y for coord in all_coords),
                               min(coord.z for coord in all_coords)))
            max_coords = Vector((max(coord.x for coord in all_coords),
                               max(coord.y for coord in all_coords),
                               max(coord.z for coord in all_coords)))
            
            model_width = max_coords.x - min_coords.x
            
            # Position reference plane to the side with some padding
            self.reference_plane.location.x = max_coords.x + model_width * 0.5
            self.reference_plane.location.z = (min_coords.z + max_coords.z) / 2
    
    def create_advanced_material(self, material_name: str = "AdvancedRustMetal") -> bpy.types.Material:
        """Create an advanced procedural rust metal material"""
        # Remove existing material with same name
        if material_name in bpy.data.materials:
            bpy.data.materials.remove(bpy.data.materials[material_name])
        
        mat = bpy.data.materials.new(material_name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # Clear default nodes
        nodes.clear()
        
        # Create nodes for advanced material
        output = nodes.new('ShaderNodeOutputMaterial')
        principled = nodes.new('ShaderNodeBsdfPrincipled')
        
        # Noise textures for variation
        noise1 = nodes.new('ShaderNodeTexNoise')
        noise2 = nodes.new('ShaderNodeTexNoise')
        
        # Color ramps for controlling rust distribution
        color_ramp1 = nodes.new('ShaderNodeValToRGB')
        color_ramp2 = nodes.new('ShaderNodeValToRGB')
        
        # Mix nodes for combining effects
        mix_rgb = nodes.new('ShaderNodeMixRGB')
        
        # Position nodes
        output.location = (400, 0)
        principled.location = (200, 0)
        mix_rgb.location = (0, 100)
        color_ramp1.location = (-200, 200)
        color_ramp2.location = (-200, 0)
        noise1.location = (-400, 200)
        noise2.location = (-400, 0)
        
        # Configure noise textures
        noise1.inputs['Scale'].default_value = 15.0
        noise1.inputs['Detail'].default_value = 10.0
        noise2.inputs['Scale'].default_value = 5.0
        noise2.inputs['Detail'].default_value = 5.0
        
        # Configure color ramps for rust effect
        color_ramp1.color_ramp.elements[0].color = (0.1, 0.05, 0.02, 1.0)  # Dark rust
        color_ramp1.color_ramp.elements[1].color = (0.6, 0.3, 0.1, 1.0)   # Light rust
        
        color_ramp2.color_ramp.elements[0].color = (0.2, 0.2, 0.25, 1.0)  # Metal base
        color_ramp2.color_ramp.elements[1].color = (0.8, 0.8, 0.85, 1.0)  # Shiny metal
        
        # Configure mix node
        mix_rgb.blend_type = 'MIX'
        mix_rgb.inputs['Fac'].default_value = 0.7
        
        # Configure principled BSDF
        principled.inputs['Metallic'].default_value = 0.9
        principled.inputs['Roughness'].default_value = 0.6
        
        # Link nodes
        links.new(noise1.outputs['Fac'], color_ramp1.inputs['Fac'])
        links.new(noise2.outputs['Fac'], color_ramp2.inputs['Fac'])
        links.new(color_ramp1.outputs['Color'], mix_rgb.inputs['Color1'])
        links.new(color_ramp2.outputs['Color'], mix_rgb.inputs['Color2'])
        links.new(mix_rgb.outputs['Color'], principled.inputs['Base Color'])
        links.new(principled.outputs['BSDF'], output.inputs['Surface'])
        
        logger.info(f"Created advanced material: {material_name}")
        return mat
    
    def apply_materials_intelligently(self) -> None:
        """Apply materials to all mesh objects with smart detection"""
        material = self.create_advanced_material()
        
        mesh_objects = [obj for obj in self.imported_objects if obj.type == 'MESH']
        
        for obj in mesh_objects:
            # Clear existing materials
            obj.data.materials.clear()
            # Apply new material
            obj.data.materials.append(material)
            logger.info(f"Applied material to object: {obj.name}")
    
    def setup_optimal_viewport(self) -> None:
        """Setup optimal viewport settings for character modeling"""
        # In headless mode, this might not work, so wrap in try-except
        try:
            # Set to front view
            for area in bpy.context.screen.areas:
                if area.type == 'VIEW_3D':
                    for region in area.regions:
                        if region.type == 'WINDOW':
                            override = bpy.context.copy()
                            override['area'] = area
                            override['region'] = region
                            with bpy.context.temp_override(**override):
                                bpy.ops.view3d.view_axis(type='FRONT')
                                # Set viewport shading to material preview
                                area.spaces[0].shading.type = 'MATERIAL'
                                # Enable overlays
                                area.spaces[0].overlay.show_overlays = True
                    break
            
            logger.info("Viewport configured for optimal character modeling")
        except Exception as e:
            logger.warning(f"Viewport setup skipped (headless mode?): {e}")
    
    def save_result(self, filename: str = "BlendAI_Result.blend") -> bool:
        """Save the result to output directory"""
        try:
            output_path = self.output_dir / filename
            bpy.ops.wm.save_as_mainfile(filepath=str(output_path))
            logger.info(f"Saved result to: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to save result: {e}")
            return False
    
    def export_fbx(self, filename: str = "BlendAI_Export.fbx") -> bool:
        """Export the result as FBX"""
        try:
            output_path = self.output_dir / filename
            bpy.ops.export_scene.fbx(filepath=str(output_path))
            logger.info(f"Exported FBX to: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to export FBX: {e}")
            return False
    
    def render_preview(self, filename: str = "BlendAI_Preview.png") -> bool:
        """Render a preview image"""
        try:
            output_path = self.output_dir / filename
            
            # Set up basic render settings
            scene = bpy.context.scene
            scene.render.filepath = str(output_path)
            scene.render.image_settings.file_format = 'PNG'
            scene.render.resolution_x = 1920
            scene.render.resolution_y = 1080
            
            # Render
            bpy.ops.render.render(write_still=True)
            logger.info(f"Rendered preview to: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to render preview: {e}")
            return False
    
    def run_complete_setup(self, save_blend: bool = True, export_fbx: bool = True, render_preview: bool = True) -> bool:
        """Execute the complete smart setup workflow"""
        logger.info("Starting BlendAI smart setup for Ubuntu Server...")
        
        if not self.validate_files():
            return False
        
        # Clear scene but keep camera and lights
        self.clear_scene(keep_camera_light=True)
        
        # Import model
        if not self.import_model():
            return False
        
        # Setup reference image
        if not self.setup_reference_image():
            logger.warning("Reference image setup failed, continuing without it")
        
        # Apply materials
        self.apply_materials_intelligently()
        
        # Setup viewport (may not work in headless)
        self.setup_optimal_viewport()
        
        # Save and export results
        success = True
        if save_blend:
            success &= self.save_result()
        
        if export_fbx:
            success &= self.export_fbx()
        
        if render_preview:
            success &= self.render_preview()
        
        if success:
            logger.info("BlendAI setup completed successfully!")
            print(f"✅ Results saved to: {self.output_dir}")
        else:
            logger.error("Some operations failed during setup")
        
        return success

def main():
    """Main function with command line argument parsing"""
    parser = argparse.ArgumentParser(description='BlendAI Ubuntu Server Automation')
    parser.add_argument('--model', '-m', required=True, help='Path to FBX model file')
    parser.add_argument('--reference', '-r', required=True, help='Path to reference image')
    parser.add_argument('--output', '-o', default='/tmp/blendai_output', help='Output directory')
    parser.add_argument('--no-save', action='store_true', help='Skip saving .blend file')
    parser.add_argument('--no-export', action='store_true', help='Skip FBX export')
    parser.add_argument('--no-render', action='store_true', help='Skip preview render')
    
    args = parser.parse_args()
    
    # Create and run setup
    setup = BlendAISetup(args.model, args.reference, args.output)
    success = setup.run_complete_setup(
        save_blend=not args.no_save,
        export_fbx=not args.no_export,
        render_preview=not args.no_render
    )
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

# Usage when running as a script
if __name__ == "__main__":
    # Check if running with command line arguments
    if len(sys.argv) > 1:
        main()
    else:
        # Default usage with hardcoded paths (update these)
        base_model_path = "/path/to/your/ForgottenKing_Base.fbx"
        reference_image_path = "/path/to/your/forgotten_king_ref.png"
        
        setup = BlendAISetup(base_model_path, reference_image_path)
        success = setup.run_complete_setup()
        
        if success:
            print("✅ BlendAI setup completed successfully!")
        else:
            print("❌ BlendAI setup failed. Check the console for details.")