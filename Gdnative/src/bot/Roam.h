#ifndef ROAM_H
#define ROAM_H

#include <State.h>
#include <Array.hpp>

namespace godot
{	
	class Roam : public State
	{
		
	private:

		bool _on_dest = true;
		int _current_dest_id = 0;

		godot::Array _path_to_dest;

	private:

		void headToDest();

	public:
		
		static void _register_methods(){}

		virtual void runState();
		virtual bool isStateReady();
		virtual void startState();

	};
}
#endif