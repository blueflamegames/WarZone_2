#ifndef NAVIGATE_H
#define NAVIGATE_H

#include <Godot.hpp>
#include <Destination.h>
#include <stack>

namespace godot
{
    class Bot;
    class navigate
    {
    private:

        Node2D *_parent;
        Navigation2D *_nav;
        Bot *_bot;
        std::stack<Destination> _places;
        int _max_places {5};
    
    private:

        //This function prevents bots from being stuck when they collide with each other.
        bool _handleCollisionWithFriend();
    
    public:

        bool on_final_destination {true};
        Vector2 world_size {Vector2(1500,1500)};
        
    public:

        navigate(Node2D *par, Navigation2D *nav, Bot *bot);
       
        //add a new location to visit.
        void addPlace(const Vector2 &place);
        
        //move to specified location.
        void move();
        
        //generates a random location to visit.
        void getRandomLocation();

        //returns square of distanec between 2 points.
        static float sqDistance(const Vector2 &v1, const Vector2 &v2);
        static float sq(float v) {return v*v;}
        ~navigate();
    };    
}


#endif