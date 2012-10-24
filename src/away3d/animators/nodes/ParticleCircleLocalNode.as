package away3d.animators.nodes
{
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.data.ParticleParamter;
	import away3d.animators.states.ParticleCircleLocalState;
	import away3d.animators.utils.ParticleAnimationCompiler;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	/**
	 * ...
	 */
	public class ParticleCircleLocalNode extends LocalParticleNodeBase
	{
		public static const NAME:String = "ParticleCircleLocalNode";
		public static const CIRCLE_STREAM_REGISTER:int = 0;
		public static const EULERS_CONSTANT_REGISTER:int = 1;
		
		private var _eulers:Vector3D;
		private var _eulersMatrix:Matrix3D;
		
		
		public function ParticleCircleLocalNode(eulers:Vector3D=null)
		{
			super(NAME);
			_stateClass = ParticleCircleLocalState;
			
			_eulers = new Vector3D();
			if (eulers)_eulers = eulers.clone();
			_eulersMatrix = new Matrix3D();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			
			//TODO: If do not need velocity, it can be reduced to 2
			_dataLenght = 3;
			initOneData();
		}
		
		public function get eulers():Vector3D
		{
			return _eulers;
		}
		
		public function set eulers(value:Vector3D):void
		{
			_eulers = value;
			_eulersMatrix.identity();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			//_eulersMatrix.transpose();
		}
		
		public function get eulersMatrix():Matrix3D
		{
			return _eulersMatrix;
		}
		
		override public function generatePorpertyOfOneParticle(param:ParticleParamter):void
		{
			//Vector3D.x is radius,Vector3D.y is cycle
			var temp:Vector3D = param[NAME];
			if (!temp)
				throw new Error("there is no " + NAME + " in param!");
				
			_oneData[0] = temp.x;
			_oneData[1] = Math.PI * 2 / temp.y;
			_oneData[2] = temp.x * Math.PI * 2;
		}
		
		override public function getAGALVertexCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, activatedCompiler:ParticleAnimationCompiler) : String
		{
			
			var circleAttribute:ShaderRegisterElement = activatedCompiler.getFreeVertexAttribute();
			activatedCompiler.setRegisterIndex(this, CIRCLE_STREAM_REGISTER, circleAttribute.index);
			
			var eulersMatrixRegister:ShaderRegisterElement = activatedCompiler.getFreeVertexConstant();
			activatedCompiler.setRegisterIndex(this, EULERS_CONSTANT_REGISTER, eulersMatrixRegister.index);
			activatedCompiler.getFreeVertexConstant();
			activatedCompiler.getFreeVertexConstant();
			activatedCompiler.getFreeVertexConstant();
			
			var temp1:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			activatedCompiler.addVertexTempUsages(temp1,1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index);
			
			
			var temp2:ShaderRegisterElement = activatedCompiler.getFreeVertexVectorTemp();
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "y");
			var degree:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "z");
			activatedCompiler.removeVertexTempUsage(temp1);
			
			var code:String = "";
			code += "mul " + degree.toString() + "," + activatedCompiler.vertexTime.toString() + "," + circleAttribute.toString() + ".y\n";
			code += "cos " + cos.toString() +"," + degree.toString() + "\n";
			code += "sin " + sin.toString() +"," + degree.toString() + "\n";
			code += "mul " + distance.toString() +".x," + cos.toString() +"," + circleAttribute.toString() + ".x\n";
			code += "mul " + distance.toString() +".y," + sin.toString() +"," + circleAttribute.toString() + ".x\n";
			code += "mov " + distance.toString() + ".wz" + activatedCompiler.vertexZeroConst.toString() + "\n";
			code += "m44 " + distance.toString() + "," + distance.toString() + "," +eulersMatrixRegister.toString() + "\n";
			code += "add " + activatedCompiler.offsetTarget.toString() + ".xyz," + distance.toString() + ".xyz," + activatedCompiler.offsetTarget.toString() + ".xyz\n";
			
			if (sharedSetting.needVelocity)
			{
				code += "neg " + distance.toString() + ".x," + sin.toString() + "\n";
				code += "mov " + distance.toString() + ".y," + cos.toString() + "\n";
				code += "mov " + distance.toString() + ".zw," + activatedCompiler.vertexZeroConst.toString() + "\n";
				code += "m44 " + distance.toString() + "," + distance.toString() + "," +eulersMatrixRegister.toString() + "\n";
				code += "mul " + distance.toString() + "," + distance.toString() + "," +circleAttribute.toString() + ".z\n";
				code += "div " + distance.toString() + "," + distance.toString() + "," +circleAttribute.toString() + ".y\n";
				code += "add " + activatedCompiler.velocityTarget.toString() + ".xyz," + activatedCompiler.velocityTarget.toString() + ".xyz," +distance.toString() + ".xyz\n";
			}
			return code;
		}
		
	}

}