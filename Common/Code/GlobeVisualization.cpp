//
//  GlobeVisualization.cpp
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-31.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "GlobeVisualization.hpp"

Point3 GlobeVisualization::nodePosition(NodePointer node) {
    if(!node->hasLatLong) {
        return DefaultVisualization::nodePosition(node);
    }
    
    float r = 1.0;
    float x = r * cos(node->latitude) * cos(node->longitude);
    float y = r * cos(node->latitude) * sin(node->longitude);
    float z = r * sin(node->latitude);
    return Point3(x, y, z);
}



Color GlobeVisualization::nodeColor(NodePointer node) {
    if(!node->hasLatLong) {
        return Color(0.0f, 0.0f, 0.0f, 0.0f);
    }

    return DefaultVisualization::nodeColor(node);
}
