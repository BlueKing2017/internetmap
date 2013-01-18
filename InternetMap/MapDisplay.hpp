//
//  MapDisplay.hpp
//  InternetMap
//


#ifndef InternetMap_MapDisplay_hpp
#define InternetMap_MapDisplay_hpp


#include "Types.hpp"

class Camera;
class Program;
class DisplayNodes;
class DisplayLines;

class MapDisplay {
    void bindDefaultNodeUniforms(shared_ptr<Program> program);

    shared_ptr<Program> _nodeProgram;
    shared_ptr<Program> _selectedNodeProgram;
    shared_ptr<Program> _connectionProgram;

    float _displayScale;

public:
    MapDisplay();
    
    void setDisplayScale(float f) { _displayScale = f; }
    float getDisplayScale() { return _displayScale;}
    
    shared_ptr<Camera> camera;
    shared_ptr<DisplayNodes> nodes;
    shared_ptr<DisplayNodes> selectedNodes;
    shared_ptr<DisplayLines> visualizationLines;
    shared_ptr<DisplayLines> highlightLines;
    
    void update(TimeInterval currentTime);
    void draw(void);
};

#endif
