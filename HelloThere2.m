function HelloThere2

%References the BpodSystem so Matlab can access it
global BpodSystem

%Creates a structure to save the task parameters
%This struct will contain the time to hold for the nose poke and 
% the time to wait for the light to turn back on.
S = struct;

S.PokeTime = 5; %Time to hold the nose poke (s)
S.LightOnTime = 5; %Time to wait before turning the light back on
S.TimeoutTime = 5; %Time to wait between sessions

%Now it is time to define a trial for each behavorial response
%The trial types will be 1 = Left, 2 = Middle, 3 = Right
%A vector of 10 values in the range 1-3 is created to indicate the trial
%type
TrialTypes = ceil(rand(1, 10) * 1);

%This fuction converts the volume of fluid into the amount of time in which
%the pump should be open
ValveTime = GetValveTimes(5, [1]);
% MidValveTime = R(1);
% MidValveTime = R(2);
% RightValveTime = R(3);

%Now need to set up a main loop for the program to run.
for currentTrial = 1:3
    
    %Selects the trial type to be used for the current trial
    switch TrialTypes(currentTrial)
        case 1 %Mid Nose Poke
            MidPortAction = 'Reward';
            Stimulus = {'PWM1', 255};
            ValveCode = 2;
%         case 2 %Left Nose Poke
%             LeftPortAction = 'Reward';
%             Stimulus = {'PWM1', 255};
%             ValveCode = 1;
    end
    
    %Now a blank state matrix is created to define the finite state machine
    StateMatrix = NewStateMatrix();
    
    %Add a state for the initial nose poke
    StateMatrix = AddState(StateMatrix, ...
        'Name', 'LightOn', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Port1In', 'NosePoke'}, ...
        'OutputActions', Stimulus);
    %Add a state to detect if the nose leaves the port before the time is
    %up
    StateMatrix = AddState(StateMatrix, ...
        'Name', 'NosePoke', ...
        'Timer', S.PokeTime, ...
        'StateChangeConditions', {'Tup', 'Reward', 'Port1Out', 'LightOn'}, ...
        'OutputActions', {});
    %Add a state to reward the mouse with a water reward
    StateMatrix = AddState(StateMatrix, ...
        'Name', 'Reward', ...
        'Timer', ValveTime, ...
        'StateChangeConditions', {'Tup', 'Timeout'}, ...
        'OutputActions', {'ValveState', ValveCode});
    %Add a state to wait a specific amount of time before beginning the
    %next trial
    StateMatrix = AddState(StateMatrix, ...
        'Name', 'Timeout', ...
        'Timer', S.TimeoutTime, ...
        'StateChangeConditions', {'Tup' 'exit'}, ...
        'OutputActions', {});
    
    %Now it is time to send the state to the Bpod device
    SendStateMatrix(StateMatrix);
    
    %Actually remember to run the state matrix lol
    RawEvents = RunStateMatrix;
    
    %Setup for data gathering
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
    
    %Adds Trial information to the Bpod data save
    BpodSystem.Data.TrialSettings(currentTrial) = S;
    
    BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial);
    
    %Save the data
    SaveBpodSessionData;
    
    %Handle pause conditon
    HandlePauseCondition;
    
    %Handle Ending of the session from the console
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    
    
end


