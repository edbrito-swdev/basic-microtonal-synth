// number of the device to open (see: chuck --probe)
1 => int deviceIn;
//0 => int deviceOut;

// the midi in event
MidiIn min;
// the message for retrieving data
MidiMsg msg;
// instantiate a MIDI out object
//MidiOut mout;

// make our own event
class NoteEvent extends Event
{
    int note;
    int velocity;
}

// the event
NoteEvent on;
// array of ugen's handling each note
Event @ us[128];
// mapped keys to TET 31
int mappedKeys[384];
for (0 => int i; i < 384; i++) {
    -1 => mappedKeys[i];
}

72 => int currentMidiNote;
0 => int currentIndex;

for (0 => int i; i < 4; i++) {
    i*12 => int offset;
    currentIndex++ => mappedKeys[72 + offset]; // starts at C4
    currentIndex++ => mappedKeys[74 + offset];
    currentIndex++ => mappedKeys[76 + offset];
    currentIndex++ => mappedKeys[77 + offset];
    currentIndex++ => mappedKeys[79 + offset];
    currentIndex++ => mappedKeys[81 + offset];
    currentIndex++ => mappedKeys[83 + offset];
}
currentIndex++ => mappedKeys[72 + 48];
currentIndex++ => mappedKeys[74 + 49];
currentIndex++ => mappedKeys[76 + 50];


// base patch
Gain g => dac;
.1 => g.gain;


440 => float upperNote;
220 => float lowerNote;

31 => int TET;
(upperNote - lowerNote) / TET => float toneStep;
float notes[TET+1];

lowerNote => float currentNote;
for( 0 => int note; note <= TET; note++ ) {
    currentNote => notes[note];
    currentNote + toneStep => currentNote;
}

// open the device for input
if( !min.open( deviceIn ) ) {
    <<< "Can't open MIDI device in" >>>; 
    me.exit();
}

// open a MIDI device for output
//if( !mout.open( deviceOut ) ) {
  //  <<< "Can't open MIDI device out" >>>;
  //  me.exit();
//}

// print out device that was opened for input
<<< "MIDI device in:", min.num(), " -> ", min.name() >>>;

// print out device that was opened for output
//<<< "MIDI device out:", mout.num(), " -> ", mout.name() >>>;

// handler for a single voice
fun void handler()
{
    // don't connect to dac until we need it
    SinOsc m;
    Event off;
    int note;
    
    while( true )
    {
        on => now;
        on.note => note;
        <<< "Note: ", note, " Mapped note: ", mappedKeys[note] >>>;
        if (mappedKeys[note] == -1) {
            continue;
        }
        // dynamically repatch
        m => g;
        notes[mappedKeys[note]] => m.freq;
        off @=> us[note];
        
        off => now;
        null @=> us[note];
        m =< g;
    }
}

// spork handlers, one for each voice
for( 0 => int i; i < 20; i++ ) spork ~ handler();

// infinite time-loop
while( true )
{
    // wait on the event 'min'
    min => now;
    
    // get the message(s)
    while( min.recv(msg) )
    {
        // print out midi message
        if( (msg.data1 & 0xf0) == 0x90 ) {
            if( msg.data3 > 0 ) {
                <<< msg.data1 >>>;
                <<< msg.data2 >>>;
                // store midi note number
                msg.data2 => on.note;
                // store velocity
                msg.data3 => on.velocity;
                // signal the event
                on.signal();
                // yield without advancing time to allow shred to run
                me.yield();
            }
            else
            {
                if( us[msg.data2] != null ) us[msg.data2].signal();
            }
        }
        else if( (msg.data1 & 0xf0) == 0x80 ) {
            us[msg.data2].signal();
       }
       // mout.send (msg);
    }
}
