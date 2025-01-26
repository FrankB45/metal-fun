//
//  shader.metal
//  metal-fun
//
//  Created by Frank Baiata on 1/19/25.
//
#include <metal_stdlib>
#include <simd/simd.h>
#include "definitions.h"

using namespace metal;



struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
};

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]]){
    
    //Hardcoded Data for now
    float4 positions[3] = {
        float4( 0.0, 0.5, 0.0, 1.0) ,
        float4( -0.5, -0.5, 0.0, 1.0),
        float4( 0.5, -0.5, 0.0, 1.0)
    };
    
    RasterizerData output;
    
    output.position = positions[vertexID];
    output.color = float4(1.0,0.0,0.0,1.0);
    
    
    return output;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]){
    //Return the interpolated color
    return in.color;
}

