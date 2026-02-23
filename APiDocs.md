Functions and BlueprintEvents🔗
Plain Script Functions🔗
Functions can be declared as methods in a class or globally. By default any function you declare can only be called from script and is not accessible to blueprint.

class AExampleActor : AActor
{
    void MyMethod()
    {
        MyGlobalFunction(this);
    }
}

void MyGlobalFunction(AActor Actor)
{
    if (!Actor.IsHidden())
    {
        Actor.DestroyActor();
    }
}
Functions that can be called from Blueprint🔗
To make it so a function can be called from blueprint, add a UFUNCTION() specifier above it.

class AExampleActor : AActor
{
    UFUNCTION()
    void MyMethodForBlueprint()
    {
        Print("I can be called from a blueprint!");
    }
}
Note: Unlike in C++, it is not necessary to specify BlueprintCallable, it is assumed by default.

Overriding BlueprintEvents from C++🔗
To override a Blueprint Event declared from a C++ parent class, use the BlueprintOverride specifier. You will use this often to override common events such as BeginPlay or Tick:

class AExampleActor : AActor
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Print("I am a BeginPlay override");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Print("I get called every tick");
    }
}
The visual studio code extension has helpers for easily overriding blueprint events from parent classes.

When the cursor is within a class, you can click the Lightbulb icon (or press Ctrl + . by default) to choose a function to override:



Typing the name of an overridable event also suggests a completion for the full function signature:



Note: For C++ functions that don't explicitly specify a ScriptName meta tag, some name simplification is automatically done to remove common prefixes.
For example, the C++ event is called ReceiveBeginPlay, but the preceeding Receive is removed and it just becomes BeginPlay in script.
Other prefixes that are removed automatically are BP_, K2_ and Received_.

Overriding a Script Function from Blueprint🔗
Often you will want to create a blueprint that inherits from a script parent class. In order to make a function so it can be overridden from a child blueprint, add the BlueprintEvent specifier.

class AExampleActor : AActor
{
    UFUNCTION(BlueprintEvent)
    void OverridableFunction()
    {
        Print("This will only print if not overridden from a child BP.");
    }
}
Note: Script has no split between BlueprintImplementableEvent and BlueprintNativeEvent
like C++ has. All script functions require a base implementation, although it can be left empty.

Tip: Separate Blueprint Events🔗
One pattern that is employed often in Unreal is to have separate base and blueprint events. This way you can guarantee that the script code always runs in addition to nodes in the child blueprint, and you will never run into issues if the blueprint hasn't done "Add call to parent function".

For example, a pickup actor might do:

class AExamplePickupActor : AActor
{
    void PickedUp()
    {
        // We always want this script code to run, even if our blueprint child wants to do something too
        Print(f"Pickup {this} was picked up!");
        SetActorHiddenInGame(false);

        // Call the separate blueprint event
        BP_PickedUp();
    }

    // Allows blueprints to add functionality, does not contain any code
    UFUNCTION(BlueprintEvent, DisplayName = "Picked Up")
    void BP_PickedUp() {}
}


Global Functions🔗
Any script function in global scope can also have UFUNCTION() added to it. It will then be available to be called from any blueprint like a static function.

This lets you create functions not bound to a class, similar to how Blueprint Function Libraries work.

// Example global function that moves an actor somewhat
UFUNCTION()
void ExampleGlobalFunctionMoveActor(AActor Actor, FVector MoveAmount)
{
    Actor.ActorLocation += MoveAmount;
}


Tip: Comments above function declarations become tooltips in blueprint, just like in C++

Calling Super Methods🔗
When overriding a script function with another script function, you can use the same Super:: syntax from Unreal to call the parent function. Note that script methods can be overridden without needing BlueprintEvent on the base function (all script methods are virtual). However, when overriding a BlueprintEvent, you will need to specify BlueprintOverride on the overrides.

class AScriptParentActor : AActor
{
    void PlainMethod(FVector Location)
    {
        Print("AScriptParentActor::PlainMethod()");
    }

    UFUNCTION(BlueprintEvent)
    void BlueprintEventMethod(int Value)
    {
        Print("AScriptParentActor::BlueprintEventMethod()");
    }
}

class AScriptChildActor : AScriptParentActor
{
    // Any script method can be overridden
    void PlainMethod(FVector Location) override
    {
        Super::PlainMethod(Location);
        Print("AScriptChildActor::PlainMethod()");
    }

    // Overriding a parent BlueprintEvent requires BlueprintOverride
    UFUNCTION(BlueprintOverride)
    void BlueprintEventMethod(int Value)
    {
        Super::BlueprintEventMethod(Value);
        Print("AScriptChildActor::BlueprintEventMethod()");
    }
}
Note: When overriding a C++ BlueprintNativeEvent, it is not possible to call the C++ Super method due to a technical limitation. You can either prefer creating BlueprintImplementableEvents, or put the base implementation in a separate callable function.
Properties and Accessors🔗
Script Properties🔗
Properties can be added as variables in any script class. The initial value of a property can be specified in the class body.

By default any plain property you declare can only be used from script and is not accessible to blueprint or in the editor.

class AExampleActor : AActor
{
    float ScriptProperty = 10.0;
}
Editable Properties🔗
To expose a property to unreal, add a UPROPERTY() specifier above it.

class AExampleActor : AActor
{
    // Tooltip of the property
    UPROPERTY()
    float EditableProperty = 10.0;
}


Note: It is not necessary to add EditAnywhere to properties in script. Unlike in C++, this is assumed as the default in script.

To be more specific about where/when a property should be editable from the editor UI, you can use one of the following specifiers:

class AExampleActor : AActor
{
    // Can only be edited from the default values in a blueprint, not on instances in the level
    UPROPERTY(EditDefaultsOnly)
    float DefaultsProperty = 10.0;

    // Can only be edited on instances in the level, not in blueprints
    UPROPERTY(EditInstanceOnly)
    FVector InstanceProperty = FVector(0.0, 100.0, 0.0);

    // The value can be seen from property details anywhere, but *not* changed
    UPROPERTY(VisibleAnywhere)
    FName VisibleProperty = NAME_None;

    // This property isn't editable anywhere at all
    UPROPERTY(NotEditable)
    TArray<int> VisibleProperty;
}
Blueprint Accessible Properties🔗
When a property is declared with UPROPERTY(), it also automatically becomes usable within blueprint:



To limit the blueprint from reading or writing to the property, you can use one of the following specifiers:

class AExampleActor : AActor
{
    // This property can be both read and written from blueprints
    UPROPERTY()
    float BlueprintProperty = 10.0;

    // This property can use `Get` nodes in blueprint, but not `Set` nodes
    UPROPERTY(BlueprintReadOnly)
    float ReadOnlyProperty = 0.0;

    // This property cannot be accessed by blueprint nodes at all
    UPROPERTY(BlueprintHidden)
    int NoBlueprintProperty = 5;
}
Note: It is not necessary to add BlueprintReadWrite to properties in script. Unlike in C++, this is assumed as the default in script.

Categories🔗
It can be helpful to specify a Category for your properties. Categories help organize your properties in the editor UI:

class AExampleActor : AActor
{
    UPROPERTY(Category = "First Category")
    float FirstProperty = 0.0;

    UPROPERTY(Category = "Second Category")
    float SecondProperty = 0.0;

    UPROPERTY(Category = "Second Category|Child Category")
    FString ChildProperty = "StringValue";
}


Property Accessor Functions🔗
Script methods that start with Get..() or Set..() can use the property keyword to allow them to be used as if they are properties. When the property value is used within other code, the appropriate Get or Set function is automatically called:

class AExampleActor : AActor
{
    // The `property` keyword lets this function be used as a property instead
    FVector GetRotatedOffset() const property
    {
        return ActorRotation.RotateVector(FVector(0.0, 1.0, 1.0));
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // This automatically calls GetRotatedOffset() when used as a property
        Print("Offset at BeginPlay: "+RotatedOffset);
    }
}
Property Accessors in C++ Binds🔗
Note that all C++ binds can be used as property accessors regardless. That means that any C++ function that starts with Get...() can be accessed as a property.

This lets you access things such as Actor.ActorLocation as a property. For C++ binds, both forms are valid, so ActorLocation and GetActorLocation() produce the same result.

Access Modifiers🔗
If you want a property or function to be private or protected in script, each individual property needs to be specified that way:

class AExampleActor : AActor
{
    private FVector Offset;
    protected bool bIsMoving = false;

    bool IsMoving() const
    {
        return bIsMoving;
    }

    protected void ToggleMoving()
    {
        bIsMoving = !bIsMoving;
    }
}
Properties that are private cannot be accessed at all outside the class they are declared in. Properties that are protected can only be accessed by the class itself and its children.

Tip: Access modifiers work for functions as well as for properties.

Actors and Components🔗
Actors and components are two of the fundamental gameplay types in unreal code.

Creating a new actor or component type in script is as simple as creating a new script file and adding a class that inherits from an actor type:

class AMyActor : AActor
{
}

class UMyComponent : UActorComponent
{
}
Note: The script plugin automatically sets the most useful class flags for any script classes, adding a UCLASS() specifier is not necessary in script, but can still optionally be used to configure additional class settings.

Default Components🔗
Unlike in C++, script classes do not make use of their constructors for creating components. To add a default component to the actor, use the DefaultComponent specifier for them. Default components are automatically created on the actor when it is spawned.

The following class will have two components on it when placed. A scene component at the root, and the custom UMyComponent we declared before:

class AExampleActor : AActor
{
    UPROPERTY(DefaultComponent)
    USceneComponent SceneRoot;
    UPROPERTY(DefaultComponent)
    UMyComponent MyComponent;
}
Component Attachments🔗
Likewise, the default attachment hierarchy is specified in UPROPERTY specifiers, rather than set up in a constructor. Use the Attach = and AttachSocket = specifiers.

If an explicit attachment is not specified, the component will be attached to the actor's root.

class AExampleActor : AActor
{
    // Explicit root component
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    // Will be attached to SceneRoot by default, as no attachment is specified
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent CharacterMesh;

    // Will be attached to the CharacterMesh' RightHand socket
    UPROPERTY(DefaultComponent, Attach = CharacterMesh, AttachSocket = RightHand)
    UStaticMeshComponent WeaponMesh;

    // Will be attached to the WeaponMesh
    UPROPERTY(DefaultComponent, Attach = WeaponMesh)
    UStaticMeshComponent ScopeMesh;
}


Note: You can explicitly note which component should be the default root component with the RootComponent specifier. If you do not add this specifier, the first component to be created will become the root.

Default Statements🔗
To assign default values to properties on the actor's components, you can use default statements:

class AExampleActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent CharacterMesh;

    // The character mesh is always placed a bit above the actor root
    default CharacterMesh.RelativeLocation = FVector(0.0, 0.0, 50.0);

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent ShieldMesh;

    // The shield mesh is hidden by default, and should only appear when taking damage
    default ShieldMesh.bHiddenInGame = true;
    // The shield mesh should not have any collision
    default ShieldMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
}
Working with Components🔗
Retrieving Components🔗
If you have an actor and want to find a component of a type on it, use UMyComponentClass::Get():

AActor Actor;

// Retrieve the first skeletal mesh component we can find on the actor
USkeletalMeshComponent SkelComp = USkeletalMeshComponent::Get(Actor);

// Find the specific skeletal mesh component with this component name
USkeletalMeshComponent WeaponComp = USkeletalMeshComponent::Get(Actor, n"WeaponMesh");
If no component of the specified type exists, this will return nullptr.

Use UMyComponentClass::GetOrCreate() to retrieve a potential existing component, or create it if one does not exist already:

// Find our own interaction handling component on the actor.
// If it does not exist, create it.
UInteractionComponent InteractComp = UInteractionComponent::GetOrCreate(Actor);

// Find an interaction handling component specifically named "ClimbingInteraction",
// or create a new one with that name
auto ClimbComp = UInteractionComponent::GetOrCreate(Actor, n"ClimbingInteraction");
Adding New Components🔗
Creating a new component works similarly by calling UMyComponentClass::Create(). Specifying a component name is optional, if none is specified one will be automatically generated.

ACharacter Character;

// Create a new static mesh component on the character and attach it to the character mesh
UStaticMeshComponent NewComponent = UStaticMeshComponent::Create(Character);
NewComponent.AttachToComponent(Character.Mesh);
Tip: If you have a dynamic TSubclassOf<> or UClass for a component class, you can also use the generic functions on actors for these operations by using Actor.GetComponent(), Actor.GetOrCreateComponent(), or Actor.CreateComponent()

Spawning Actors🔗
Actors can be spawned by using the global SpawnActor() function:

// Spawn a new Example Actor at the specified location and rotation
FVector SpawnLocation;
FRotator SpawnRotation;
AExampleActor SpawnedActor = SpawnActor(AExampleActor, SpawnLocation, SpawnRotation);
Spawning a Blueprinted Actor🔗
It is often needed to dynamically spawn an actor blueprint, rather than a script actor baseclass. To do this, use a TSubclassOf<> property to reference the blueprint, and use the global SpawnActor() function.

An example of a spawner actor that can be configured to spawn any blueprint of an example actor:

class AExampleSpawner : AActor
{
    /**
     * Which blueprint example actor class to spawn.
     * This needs to be configured either in the level,
     * or on a blueprint child class of the spawner.
     */
    UPROPERTY()
    TSubclassOf<AExampleActor> ActorClass;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FVector SpawnLocation;
        FRotator SpawnRotation;

        AExampleActor SpawnedActor = SpawnActor(ActorClass, SpawnLocation, SpawnRotation);
    }
}
Construction Script🔗
Actor construction script can be added by overriding the ConstructionScript() blueprint event. From construction scripts, you can create new components and override properties like normal.

For example, an actor that creates a variable amount of meshes inside it based on its settings in the level could look like this:

class AExampleActor : AActor
{
    // How many meshes to place on the actor
    UPROPERTY()
    int SpawnMeshCount = 5;

    // Which static mesh to place
    UPROPERTY()
    UStaticMesh MeshAsset;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        Print(f"Spawning {SpawnMeshCount} meshes from construction script!");

        for (int i = 0; i < SpawnMeshCount; ++i)
        {
            // Construct a new static mesh on this actor
            UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this);
            // Set the mesh we wanted for it
            MeshComp.SetStaticMesh(MeshAsset);
        }
    }
}
Getting All Actors or Components🔗
To get all components of a particular type that are on an actor, use Actor.GetComponentsByClass() and pass in the array. This function takes a ? parameter, and will determine which component type to look for by the type of array you pass in.

For example, to get all static meshes on an actor:

AActor Actor;

TArray<UStaticMeshComponent> StaticMeshComponents;
Actor.GetComponentsByClass(StaticMeshComponents);

for (UStaticMeshComponent MeshComp : StaticMeshComponents)
{
    Print(f"Static Mesh Component: {MeshComp.Name}");
}
Similarly, to get all actors of a particular type that are currently in the world, use the GetAllActorsOfClass() global function, and pass in an array of the type of actor you want:

// Find all niagara actors currently in the level
TArray<ANiagaraActor> NiagaraActors;
GetAllActorsOfClass(NiagaraActors);
Note: Getting all actors of a class requires iterating all actors in the level, and should not be used from performance-sensitive contexts. That is, try running it once and storing the value rather than using it every tick.

Override Components🔗
Unreal provides a mechanism for overriding one of a parent actor class' default components to use a child component class instead of the one specified on the parent actor. In script, this can be accessed by using the OverrideComponent specifier:

class ABaseActor : AActor
{
    // This base actor specifies a root component that is just a scene component
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;
}

class AChildActor : ABaseActor
{
    /**
     * Because static meshes are a type of scene component,
     * we can use an override component to turn the base class' root
     * scene component into a static mesh.
     */
    UPROPERTY(OverrideComponent = SceneRoot)
    UStaticMeshComponent RootStaticMesh;
}
Note: Override components are similar to using ObjectInitializer.SetDefaultSubobjectClass() in a C++ constructor.

FName Literals🔗
A lot of unreal systems use FName to efficiently pass around arbitrary names without having to copy and compare strings a lot. The name struct itself is just an index into a name table, and creating an FName from a string does a table lookup or inserts a new entry into the table.

A common pattern in C++ is to declare a global/static variable for an FName constant to use, so that the name table lookup only happens once at startup.

In angelscript, this pattern is simplified by using name literals. Any string that is declared as n"NameLiteral" will be initialized at angelscript compile time, removing the nametable lookup from runtime.

Name literals have many uses. An example of using a name literal to bind a delegate to a UFUNCTION() in angelscript:

delegate void FExampleDelegate();

class ANameLiteralActor : AActor
{
    TMap<FName, int> ValuesByName;

    void UseNameLiteral()
    {
        FName NameVariable = n"MyName";
        ValuesByName.Add(NameVariable, 1);

        FExampleDelegate Delegate;
        Delegate.BindUFunction(this, n"FunctionBoundToDelegate");
        Delegate.ExecuteIfBound();

        // Due to the name literal, no string manipulation happens
        // in calls to UseNameLiteral() during runtime.
    }

    UFUNCTION()
    void FunctionBoundToDelegate()
    {
        Print("Delegate executed");
    }
}

Formatted Strings🔗
Scripts have support for writing formatted string literals in order to place the value of variables or expressions within a string. This can be especially useful for logging or debugging.

The syntax and format specifiers are heavily inspired by Python's f-string feature.

Formatted strings are declared with the prefix f"", and expression values to interpolate are contained within {}. Curly braces inside formatted strings can be escaped by doubling up. That is, f"{{" is equivalent to "{".

An example of some of the usages:

// Format Strings begin with f" and can hold expressions
// inside braces to replace within the string.
Print(f"Called from actor {GetName()} at location {ActorLocation}");

// Adding a = at the end of the expression will print the expression first
// For example:
Print(f"{DeltaSeconds =}");
// This prints:
//   DeltaSeconds = 0.01

// Format specifiers can be added following similar syntax to python's f-strings:
Print(f"Three Decimals: {ActorLocation.Z :.3}"); // Format float at three decimals of precision

Print(f"Extended to 10 digits with leading zeroes: {400 :010d}"); // 0000000400
Print(f"Hexadecimal: {20 :#x}"); // 0x14
Print(f"Binary: {1574 :b}"); // 11000100110
Print(f"Binary 32 Bits: {1574 :#032b}"); // 0b00000000000000000000011000100110

// Alignment works too
Print(f"Aligned: {GetName() :>40}"); // Adds spaces to the start of GetName() so it is 40 characters
Print(f"Aligned: {GetName() :_<40}"); // Adds underscores to the end of GetName() so it is 40 characters

// You can combine the equals with a format specifier
Print(f"{DeltaSeconds =:.0}");
// This prints:
//   DeltaSeconds = 0

// Enums by default print a full debug string
Print(f"{ESlateVisibility::Collapsed}"); // "ESlateVisibility::Collapsed (1)"
// But the 'n' specifier prints only the name of the value:
Print(f"{ESlateVisibility::Collapsed :n}"); // "Collapsed"

Structs🔗
Classes declared in script are always types of UObject, and are part of unreal's normal object system and garbage collector.

You can also make structs in script, which behave as value types:

struct FExampleStruct
{
    /* Properties with UPROPERTY() in a struct will be accessible in blueprint. */
    UPROPERTY()
    float ExampleNumber = 4.0;

    UPROPERTY()
    FString ExampleString = "Example String";

    /* Properties without UPROPERTY() will still be in the struct, but cannot be seen by blueprint. */
    float ExampleHiddenNumber = 3.0;
};
Note: Unlike classes, structs cannot have UFUNCTION()s. They can have plain script methods on them however, although they will not be usable from blueprint.

Passing and Returning Structs🔗
Structs can be passed and returned from script functions and UFUNCTIONs as normal:

UFUNCTION()
FExampleStruct CreateExampleStruct(float Number)
{
    FExampleStruct ResultStruct;
    ResultStruct.ExampleNumber = Number;
    ResultStruct.ExampleString = f"{Number}";

    return ResultStruct;
}

UFUNCTION(BlueprintPure)
bool IsNumberInStructEqual(FExampleStruct Struct, float TestNumber)
{
    return Struct.ExampleNumber == TestNumber;
}
Struct References🔗
By default, argument values in script functions are read-only. That means properties of a struct parameter cannot be changed, and non-const methods cannot be called on it.

If needed, you can take a reference to a struct to modify it:

// Change the parameter struct so its number is randomized between 0.0 and 1.0
UFUNCTION()
void RandomizeNumberInStruct(FExampleStruct& Struct)
{
    Struct.ExampleNumber = Math::RandRange(0.0, 1.0);
}
Declaring Out Parameters🔗
When a function with a struct reference is called from a blueprint node, the struct will be passed as an input value:



When you want a struct parameter to be an ouput value only, declare the reference as &out in script. This works to create output pins for primitives as well:

UFUNCTION()
void OutputRandomizedStruct(FExampleStruct&out OutputStruct, bool&out bOutSuccessful)
{
    FExampleStruct ResultStruct;
    ResultStruct.ExampleNumber = Math::RandRange(0.0, 1.0);

    OutputStruct = ResultStruct;
    bOutSuccessful = true;
}


Automatic References for Function Parameters🔗
As an implementation detail: script functions never take struct parameters by value.
When you declare a struct parameter, it is internally implemented as a const reference, as if you added const &.

This means there is no difference between an FVector parameter and a const FVector& parameter. Both behave exactly the same in performance and semantics.

This choice was made to improve script performance and avoid having to instruct gameplay scripters to write const & on all their parameters.

Unreal Networking Features🔗
Unreal networking features are supported to a similar extent as they are in blueprint.

UFUNCTION()s can be marked as NetMulticast, Client, Server and/or BlueprintAuthorityOnly in their specifiers, functioning much the same as they do in C++. The function body will automatically be used as an RPC, whether calling it from angelscript or blueprint.

Unlike C++, angelscript RPC functions default to being reliable. If you want an unreliable RPC message, put the Unreliable specifier in the UFUNCTION() declaration.

UPROPERTY()s can be marked as Replicated. Optionally, you can set a condition for their replication as well, similar to the dropdown for blueprint properties. This can be done with the ReplicationCondition specifier.

Similar to C++ and Blueprint networking, in order for RPCs and replicated properties to work, the actor and component need to be set to replicate. In angelscript this can be done using default statements.

Example:

class AReplicatedActor : AActor
{
    // Set the actor's replicates property to default to true,
    // so its declared replicated properties work.
    default bReplicates = true;

    // Will always be replicated when it changes
    UPROPERTY(Replicated)
    bool bReplicatedBool = true;

    // Only replicates to the owner
    UPROPERTY(Replicated, ReplicationCondition = OwnerOnly)
    int ReplicatedInt = 0;

    // Calls OnRep_ReplicatedValue whenever it is replicated
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_ReplicatedValue)
    int ReplicatedValue = 0;

    UFUNCTION()
    void OnRep_ReplicatedValue()
    {
        Print("Replicated Value has changed!");
    }
}
Available conditions for ReplicationCondition match the ELifetimeCondition enum in C++, and are as follows:

None
InitialOnly
OwnerOnly
SkipOwner
SimulatedOnly
AutonomousOnly
SimulatedOrPhysics
InitialOrOwner
Custom
ReplayOrOwner
ReplayOnly
SimulatedOnlyNoReplay
SimulatedOrPhysicsNoReplay
SkipReplay
It is also possible to specify ReplicatedUsing on a replicated UPROPERTY that will be called whenever the value of that property is replicated. Note that any function used with ReplicatedUsing must be declared as a UFUNCTION() so it is visible to unreal.

Delegates🔗
You must first declare a delegate type to indicate what parameters and return value your delegate wants.
In global scope:

// Declare a new delegate type with this function signature
delegate void FExampleDelegate(UObject Object, float Value);
From there, you can pass around values of your delegate type, bind them, and execute them:

class ADelegateExample : AActor
{
    FExampleDelegate StoredDelegate;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Bind the delegate so executing it calls this.OnDelegateExecuted()
        StoredDelegate.BindUFunction(this, n"OnDelegateExecuted");

        // You can also create new bound delegates by using the constructor:
        StoredDelegate = FExampleDelegateSignature(this, n"OnDelegateExecuted");
    }

    UFUNCTION()
    private void OnDelegateExecuted(UObject Object, float Value)
    {
        Print(f"Delegate was executed with object {Object} and value {Value}");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // If the delegate is bound, execute it
        StoredDelegate.ExecuteIfBound(this, DeltaSeconds);
    }
}
Note: A delegate declaration is equivalent to a DECLARE_DYNAMIC_DELEGATE() macro in C++. Functions bound to delegates are required to be declared as UFUNCTION().

Events🔗
Events are similar to delegates, but can have multiple functions added to them, rather than always being bound to only one function.

Declare events with the event keyword in global scope, then use AddUFunction() and Broadcast():

event void FExampleEvent(int Counter);

class AEventExample : AActor
{
    UPROPERTY()
    FExampleEvent OnExampleEvent;

    private int CallCounter = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Add two functions to be called when the event is broadcast
        OnExampleEvent.AddUFunction(this, n"FirstHandler");
        OnExampleEvent.AddUFunction(this, n"SecondHandler");
    }

    UFUNCTION()
    private void FirstHandler(int Counter)
    {
        Print("Called first handler");
    }

    UFUNCTION()
    private void SecondHandler(int Counter)
    {
        Print("Called second handler");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        CallCounter += 1;
        OnExampleEvent.Broadcast(CallCounter);
    }
}
Note: An event declaration is equivalent to a DECLARE_DYNAMIC_MULTICAST_DELEGATE() macro in C++. Functions added to events are required to be declared as UFUNCTION().

Events in Blueprint🔗
By declaring OnExampleEvent as a UPROPERTY() in the previous example, we allow it to be accessed from blueprint. For events this means it will appear in the Event Dispatchers list for actors in the level, and we can bind it from the level blueprint:



Tip: Automatic signature generation in Visual Studio Code🔗
If you bind a delegate or add a function to an event, and the function does not exist yet, the visual studio code extension will try to offer to create it for you.

Click the lightbulb icon or press Ctrl + ., and select the Generate Method option from the code actions dropdown:

Mixin Methods🔗
It's possible in script to declare a method on a type outside the class body. This can be useful either to add methods to types from C++, or to separate out functionality from different systems.

To do this, declare a global function with the mixin keyword. The first parameter of the mixin function is filled with the object it is called on.

// Mixin method that teleports any actor
// The first, 'Self' parameter gets set to the actor it is called on
mixin void ExampleMixinTeleportActor(AActor Self, FVector Location)
{
    Self.ActorLocation = Location;
}

void Example_MixinMethod()
{
    // Call the mixin method on an actor
    // Note how ActorReference is passed into Self automatically
    AActor ActorReference;
    ActorReference.ExampleMixinTeleportActor(FVector(0.0, 0.0, 100.0));
}
When creating mixins for structs, you can take a reference to the struct as the first parameter. This allows changes to be made to it:

mixin void SetVectorToZero(FVector& Vector)
{
    Vector = FVector(0, 0, 0);
}

void Example_StructMixin()
{
    FVector LocalValue;
    LocalValue.SetVectorToZero();
}
Note: It is also possible to create mixin functions from C++ with bindings.
See Script Mixin Libraries for details.

Gameplay Tags🔗
Gameplay Tags are used in many unreal systems. See the Unreal Documentation on Gameplay Tags for more details.

All FGameplayTag will automatically be bound to the global namespace GameplayTags. All non-alphanumeric characters, including the dot separators, are turned into underscore _.

// Assuming there is a GameplayTag named "UI.Action.Escape"
FGameplayTag TheTag = GameplayTags::UI_Action_Escape;

Editor-Only Script🔗
Some properties, functions, or classes from C++ are only available in the editor. If you try to use them in a cooked game, the script will fail to compile.

This could be things like actor labels, editor subsystems or visualizers, etc.

Preprocessor Blocks🔗
If you need to use editor-only code within a class, you can use the #if EDITOR preprocessor statement around the code. Any code within these blocks is not compiled outside of the editor, and can safely use editor-only functionality.

class AExampleActor : AActor
{
#if EDITOR
    default PivotOffset = FVector(0, 0, 10);
#endif

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR
        SetActorLabel("Example Actor Label");
#endif
    }
}
Tip: Other useful macro conditions:
EDITORONLY_DATA - Whether properties that are only relevant to the editor are readable.
RELEASE - Whether the game is built in either the Shipping or Test build configurations.
TEST - Whether the game is built in Debug, Development, or Test build configurations.

Editor-Only Directories🔗
It is also possible for complete scipt files to be skipped outside of the editor. Any folder named Editor will be completely ignored by the script compiler in cooked builds. This can be useful to put for example editor visualizer or subsystem classes under an Editor folder.

In addition to the Editor folder, the two other folder names Examples and Dev are also ignored in cooked builds.

Testing with Simulate-Cooked Mode🔗
Because of editor-only scripts, it's possible to have scripts in your project that work and compile in the editor, but will fail once the game is cooked. To make it easier to detect these errors - for instance in a CI task - you can use the -as-simulate-cooked command line parameter.

When simulate cooked mode is active, editor-only properties and classes are not available in script, and #if EDITOR blocks are compiled out.

You can use this in combination with the AngelscriptTest commandlet to make sure everything compiles. An unreal command line to test whether the scripts compile might look like:

UnrealEditor-Cmd.exe "MyProject.uproject" -as-simulate-cooked -run=AngelscriptTest

Subsystems🔗
Subsystems are one of unreal's ways to collect common functionality into easily accessible singletons. See the Unreal Documentation on Programming Subsystems for more details.

Using a Subsystem🔗
Subsystems in script can be retrieved by using USubsystemClass::Get().

void TestCreateNewLevel()
{
    auto LevelEditorSubsystem = ULevelEditorSubsystem::Get();
    LevelEditorSubsystem.NewLevel("/Game/NewLevel");
}
Note: Many subsystems are Editor Subsystems and cannot be used in packaged games.
Make sure you only use editor subsystems inside Editor-Only Script.

Creating a Subsystem🔗
To allow creating subsystems in script, helper base classes are available to inherit from that expose overridable functions.
These are:

UScriptWorldSubsystem for world subsystems
UScriptGameInstanceSubsystem for game instance subsystems
UScriptLocalPlayerSubsystem for local player subsystems
UScriptEditorSubsystem for editor subsystems
UScriptEngineSubsystem for engine subsystems
For example, a scripted world subsystem might look like this:

class UMyGameWorldSubsystem : UScriptWorldSubsystem
{
    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        Print("MyGame World Subsystem Initialized!");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        Print("Tick");
    }

    // Create functions on the subsystem to expose functionality
    UFUNCTION()
    void LookAtMyActor(AActor Actor)
    {
    }
}

void UseMyGameWorldSubsystem()
{
    auto MySubsystem = UMyGameWorldSubsystem::Get();
    MySubsystem.LookAtMyActor(nullptr);
}
Any UFUNCTIONs you've declared can also be accessed from blueprint on your subsystem:



Local Player Subsystems🔗
In case of local player subsystems, you need to pass which ULocalPlayer to retrieve the subsystem for into the ::Get() function:

class UMyPlayerSubsystem : UScriptLocalPlayerSubsystem
{
}

void UseScriptedPlayerSubsystem()
{
    ULocalPlayer RelevantPlayer = Gameplay::GetPlayerController(0).LocalPlayer;
    auto MySubsystem = UMyPlayerSubsystem::Get(RelevantPlayer);
}
Note: It is also possible to directly pass an APlayerController when retrieving a local player subsystem.

Angelscript Test Support🔗
Angelscript features a xUnit-style unit testing framework. There is also an integration test framework that can play back game scenarios and wait for some condition to occur. You can generate code coverage reports for test runs as well. FName

Unit Tests🔗
void Test_NameOfTheTestCase(FUnitTest& T)
{
    // Fails the test.
    T.AssertTrue(false);
    T.AssertEquals(1, 1 + 1);
    T.AssertNotNull(nullptr);
}
You can put test code in any Angelscript file, but by convention these are put in File_Test.as if your production code is in File.as.

Running Unit Tests🔗
Unit tests run on hot reload, so to run a test you just create a test like above, open the Unreal editor, and save the file. In Unreal, go Window > Developer Tools > Output Log and you will see lines like

Angelscript: [RUN]    Some.Angelscript.Subdir.Test_LaunchesNukesWhenCodesAreEntered
...
Angelscript: [OK]     Some.Angelscript.Subdir.Test_LaunchesNukesWhenCodesAreEntered (0.2530 ms)
Furthermore, the tests show up under the category "Angelscript" in the Test Automation tool. You will need to install that one into Unreal. See https://docs.unrealengine.com/en-US/Programming/Automation/UserGuide/index.html

You can also run tests from the command line:

Engine\Binaries\Win64\UE4Editor-Cmd.exe \Path\To\your.uproject -NullRHI -NoSound -NoSplash -ExecCmds="Automation RunTests Angelscript.UnitTests" -TestExit "Automation Test Queue Empty+Found 0 Automation Tests, based on" -unattended -stdout -as-exit-on-error
Installing a Custom Game Mode for Unit Tests🔗
You can add this line to one of your .ini files in your project to get a game mode in your tests: You can then create a blueprint at the specified location and put whatever settings you want in there. This will be used by all unit tests.

[/Script/EngineSettings.GameMapsSettings]
...
+GameModeClassAliases=(Name="UnitTest",GameMode="/Game/Testing/UnitTest/BP_UnitTestGameMode.BP_UnitTestGameMode_C")
Integration Tests🔗
Integration tests are for testing larger or longer code-flows and gameplay.

By default, each integration test has a map where you can draw up any geometry or place any actors you like.

Add this to for instance MyTestName_IntegrationTest.as:

void IntegrationTest_MyTestName(FIntegrationTest& T)
{   
}
Then you need to add a test map IntegrationTest_MyTestName.umap to /Content/Testing/ (create the dir if you don't have it in your project yet). The map name is always the same as the test name, with .umap added.

You can also configure the integration test map dir with this setting in your .ini files:

[/Script/AngelscriptCode.AngelscriptTestSettings]
IntegrationTestMapRoot=/Game/Testing/
If you would like to use a different map for an integration test, or the same map for multiple tests (e.g. testing in your existing level .umap files), create a second function with the format FString IntegrationTest_MyTestName_GetMapName() and return the full path to the map. This is something like /Game/YourProject/YourMap. You can right click the map and copy the reference to see it.

FString IntegrationTest_MyTestName_GetMapName()
{
    return "/Game/YourProject/Maps/YourMap";
}
Note: changing levels isn't supported at the moment, it breaks the GameWorld context passed to the FAngelscriptContext that the angelscript code is being executed within.

You can retrieve placed actors like this (or spawn them in the test):

// Looks up an actor in the map
AActor GetActorByLabel(UClass Class, const FName& Label)
{
#if EDITOR
    TArray<AActor> Actors;
    GetAllActorsOfClass(Class, Actors);

    for (AActor Actor: Actors)
    {
        if (Actor.GetActorLabel() == Label)
        {
            return Actor;
        }
    }

    FString AllActorLabels = "";
    for (AActor Actor: Actors)
    {
        AllActorLabels += "- " + Actor.GetActorLabel() + "\n";
    }

    if (AllActorLabels.IsEmpty())
    {
        Throw(
            "Did not find an actor with class " + Class.GetName() +
            " and label " + Label + ". In fact, there no actors in this level.");
    }
    else
    {
        Throw(
            "Did not find an actor with class " + Class.GetName() +
            " and label " + Label + ". Found these actors:\n" + AllActorLabels);
    }
#endif  // EDITOR

    Throw("GetActorByLabel is only for testing, i.e. when in EDITOR mode.");
    return nullptr;
}
Latent Automation Commands🔗
The code in the test function executes before the map is loaded and before the first frame executes. The test is not complete when the test function returns therefore, it has merely enqueued a series of latent automation commands (Unreal documentation). If we assume the test enqueues no latent commands of its own (like the one above), the test framework will enqueue the following actions (see IntegrationTest.cpp):

FWaitForMapToLoadCommand()
FEnsureWorldLoaded()
FExitGameCommand()
FReportFinished()
FFreeTest()
These execute in sequence. Each action can take multiple engine frames to execute.

The test can enqueue latent commands of its own:

void IntegrationTest_AlienShootsRepeatedly(FIntegrationTest& T)
{ 
    AActor A = GetActorByLabel(ABulletSponge::StaticClass(), n"BulletSponge");
    ABulletSponge Floor = Cast<ABulletSponge>(A);

    T.AddLatentAutomationCommand(UGetsShotXTimes(Floor, 2));
}
The action is enqueued using T.AddLatentAutomationCommand. The set of latent actions will now be:

...
FEnsureWorldLoaded()
UGetsShowXTimes()
FExitGameCommand()
...
AddLatentAutomationCommand takes a ULatentAutomationCommand:

UCLASS()
class ABulletSponge : AStaticMeshActor
{
    int NumTimesHit = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        OnTakeAnyDamage.AddUFunction(this, n"TakeAnyDamage");
    }

    UFUNCTION()
    private void TakeAnyDamage(AActor DamagedActor, float32 Damage, const UDamageType DamageType, AController InstigatedBy, AActor DamageCauser)
    {
        NumTimesHit++;
    }
}

class UGetsShotXTimes : ULatentAutomationCommand
{
    private ABulletSponge BulletSponge;
    private int ExpectedNumHits;

    UGetsShotXTimes(ABulletSponge Target, int X)
    {
        BulletSponge = Target;
        ExpectedNumHits = X;
    }

    UFUNCTION(BlueprintOverride)
    bool Update()
    {
        // Note: actors can get DestroyActor'd at any time, so fail nicely if that happens!
        ensure(IsValid(BulletSponge));
        return BulletSponge.NumTimesHit > ExpectedNumHits;
    }

    UFUNCTION(BlueprintOverride)
    FString Describe() const
    {
        return BulletSponge.GetPathName() + ": bullet sponge got hit " + BulletSponge.NumTimesHit + "/" + ExpectedNumHits;
    }
}
The game engine will keep ticking as long as Update returns false. This means you can wait on any condition you can think of. The default timeout is five seconds though, so you can't wait for too long.

You can specify default bAllowTimeout = true on a latent command to allow it to time out. This is useful if you want to test that something is not happening (e.g. check actor doesn't move out of bounds during 5 seconds).

Client/Server vs Standalone🔗
The default behaviour is to run the integration tests in a client/dedicated-server model. This will break some assumptions and code that singleplayer games use. To run it in standalone mode instead, disable Project Settings -> Angelscript Test Settings -> Use Client Server Model.

Running Integration Tests🔗
Integration tests don't run on hot reload like unit tests, so you need to invoke them through the Test Automation window in Unreal. They are run just like unit tests, see above.

To run integration tests from the command line, run the same line as for unit tests but replace Angelscript.UnitTests with Angelscript.IntegrationTests.

Complex Integration Tests🔗
You can also generate test cases dynamically:

void ComplexIntegrationTest_PotionsAreTooStrongForKnight_GetTests(TArray<FString>& OutTestCommands)
{
     for (APotion Potion: MyGame::GetPotionRegistry().GetAllPotions())
     {
         OutTestCommands.Add(Potion.GetName().ToString());
     }
}

void ComplexIntegrationTest_PotionsAreTooStrongForKnight(FIntegrationTest& T)
{
    FString PotionName = T.GetParam();
    APotion Potion = MyGame::GetPotionRegistry().LookupPotion(PotionName);
    AKnight Knight = Cast<AKnight>(GetActorByLabel(AKnight::StaticClass(), n"Knight"));
    AActor PotionSeller = GetActorByLabel(AActor::StaticClass(), n"PotionSeller");

    // Order the knight to walk over to the potion seller and try to buy a potion.
    Knight.BuyPotionFrom(PotionSeller, Potion);
    T.AddLatentAutomationCommand(UExpectResponse("My potions are too strong for you traveller.", Knight, PotionSeller));
}
If we assume you have three potions in your potion registry, this generates three test cases:

Angelscript.IntegrationTest.Your.Path.ComplexIntegrationTest_PotionsAreTooStrongForKnight[DA_Potion1]
Angelscript.IntegrationTest.Your.Path.ComplexIntegrationTest_PotionsAreTooStrongForKnight[DA_Potion2]
Angelscript.IntegrationTest.Your.Path.ComplexIntegrationTest_PotionsAreTooStrongForKnight[DA_Potion3]
A Full Example🔗
/**
 * An example of an integration test to test that saves are backwards compatible (via
 * upgrades/migrations). This could be in a file called
 * Testing/UpgradeSaveGame_IntegrationTest.as, or
 * AnythingElse/DoesntMatter_IntegrationTest.as.
 *
 * Assume that we changed the protected variable that ExampleGameMode::GetCash() uses,
 * between v1 and v2, and we want to ensure that our upgrade code (not shown)
 * successfully copies it from the old variable to the new.
 *
 * Note that angelscript does a lot of lifting around turning the automation framework
 * into integration tests. See the code for more details.
 *
 */

// define the overall test. The naming standard is important. you run this from Session
// Frontend -> Automation Tab. Search for e.g. "V1" to show this function, then tick it
// to select it.
void IntegrationTest_UpgradeSaveGameV1(FIntegrationTest& T)
{
    // queue the object that can run for more than one frame, to validate a long-running test
    T.AddLatentAutomationCommand(UTestUpgradeSaveGameV1());
}

// A function that returns an FString, with the same name as the integration test + a
// _GetMapName() suffix allows us to override the default behaviour of requiring a map
// name matching the test name.
FString IntegrationTest_UpgradeSaveGameV1_GetMapName()
{
    return "/Game/IS/Maps/ISMainMap";
}

// bulk of the work is here. You can have multiple of these
class UTestUpgradeSaveGameV1 : ULatentAutomationCommand
{
    // the sentinal value we expect to see in the loaded save. in the v1 save this is
    // stored in ExampleGameMode::Cash. In the v2 save, ExampleGameMode::GetCash()
    // should be able to retrieve this from the new CashTest variable.
    // different to what CashTest defaults to.
    float CashFromV1Save = 12345.0;

    // manually create a save in the previous version to use in the test here.
    FString V1SaveFileName = "IntegrationTest_UpgradeSaveGameV1";

    // This runs at the start of this command's lifetime in the test. GetWorld(), and
    // therefore all the automatic context places it's used, should be valid here
    // (unless you try changing the map)
    UFUNCTION(BlueprintOverride)
    void Before()
    {
        auto GM = ExampleGameMode::Get();
        auto ExampleSaveSystem = UExampleSaveSystem::Get();
        ExampleSaveSystem.SelectSaveFile(V1SaveFileName);
        // can't change the map in an integration test, so don't do a full map reload. Just deserialize
        ExampleSaveSystem.LoadWithoutReload(V1SaveFileName);
    }

    // runs each tick. Return true to pass the test. The test fails if the timeout
    // (default 5 seconds) is hit and this hasn't returned true.
    UFUNCTION(BlueprintOverride)
    bool Update()
    {
        auto GM = ExampleGameMode::Get();
        // if the gamemode is loaded from the save, and the upgrade code has run
        // successfully, the values should match.
        if (GM != nullptr && Math::IsNearlyEqual(CashFromV1Save, GM.GetCash()))
        {
            return true;
        }
        return false;
    }

    // The output in the automation test log. Show expected success condition and
    // current state for debugging when it fails. Important to check GetWorld() in case
    // it runs too early.
    UFUNCTION(BlueprintOverride)
    FString Describe() const
    {
        float ActualCash = -1.0;
        if (GetWorld() != nullptr)
        {
            auto GM = ExampleGameMode::Get();
            if (GM != nullptr)
            {
                ActualCash = GM.GetCash();
            }
        }
        return f"Expected cash: {CashFromV1Save}, Actual cash: {ActualCash} (-1 is null)";
    }
}
Code Coverage🔗
Enable code coverage in Project Settings > Editor > Angelscript Test settings (or pass -as-enable-code-coverage on the command line). Note, code coverage slows down editor startup by ~20 seconds so remember to turn it off later.

CoverageToggle

Run some tests as described above. The editor will write a report to Saved/CodeCoverage. Note: it's overwritten each time you start a new test run.

CoverageDir

Open index.html to see a summary for all your angelscript.

CoverageIndex

Open individual files to see their line coverage.

CoverageDir

Overview of Differences for C++ Unreal Developers🔗
While the script files will feel familiar to developers used to working in C++ with Unreal, there are a number of differences. Most of the differences are intended to simplify the script language for people coming in from using Blueprint.

Some differences you will most likely run into are highlighted here.

Objects Instead of Pointers🔗
Any variable declared with a UObject type is automatically an object reference. Pointers do not exist in the script language. This is similar to how object reference variables work in blueprint. There is no -> arrow operator in script, everything happens with . dots.

Note: Unlike in C++, it is not necessary to declare a property as UPROPERTY() in order to avoid it being garbage collected. All object references in script are automatically inserted into the GC.

void TeleportActorToOtherActor(AActor ActorReference, AActor TeleportToActor)
{
    FTransform TeleportToTransform = TeleportToActor.GetActorTransform();
    ActorReference.SetActorTransform(TeleportToTransform);
}
Default Accessibility for Properties🔗
UPROPERTY() variables are EditAnywhere and BlueprintReadWrite by default. This can be overridden by specifying NotBlueprintCallable or NotEditable.

The default access specifiers for properties in script can be configured from Project Settings.

The intent of this is to simplify property specifiers. Since UPROPERTY() is not needed for correct garbage collection, you should only specify it when you want it to be accessible in the editor/blueprint.

Default Callability for Functions🔗
Functions declared with UFUNCTION() are BlueprintCallable by default, even when this is not specified explicitly. This is intended to simplify function declarations, as making a script function a UFUNCTION() is generally already an indicator of wanting it to be called from blueprint.

This behavior can be turned off from Project Settings, if you prefer requiring BlueprintCallable to be explicit.

Use the default Keyword Instead of Constructors🔗
Instead of using object constructors, which can run at unpredictable times during hot reloads, any default values for properties should be specified in the class body.

For setting values on subobjects, use the default keyword:

class AExampleActor : AActor
{
    // Set default values for class properties in the class body
    UPROPERTY()
    float ConfigurableValue = 5.0;

    // Set default values for subobjects with `default` statements
    UPROPERTY(DefaultComponent)
    UCapsuleComponent CapsuleComponent;
    default CapsuleComponent.CapsuleHalfHeight = 88.0;
    default CapsuleComponent.CapsuleRadius = 40.0;
    default CapsuleComponent.bGenerateOverlapEvents = true;
}
Floating Point Width🔗
With Unreal 5.0, Epic has started using doubles for all gameplay-related vectors, rotators, etc. Rather than confuse people that are used to working with float in blueprint, they decided to keep calling these doubles float everywhere in the editor like before.

The angelscript integration follows this decision, meaning that when you declare a float in script, it is actually a 64-bit double value. To create a floating-point variable with a specific width, you can explicitly use the float32 or float64 types.

float ValueDouble = 1.0; // <-- This is a 64-bit double-precision float
float32 ValueSingle = 1.f; // <-- This is a 32-bit single-precision float
float64 ValueAlsoDouble = 1.0; // <-- This is *also* a 64-bit double-precision float

FUNCTION liberaries 

Math
Math
Static Functions
CeilToFloat
static float Math::CeilToFloat(	
float 	F
)
RandRange
static int Math::RandRange(	
int 	Min,
int 	Max
)
RandRange
static float Math::RandRange(	
float 	Min,
float 	Max
)
RandRange
static float32 Math::RandRange(	
float32 	Min,
float32 	Max
)
RandBool
static bool Math::RandBool()
VRand
static FVector Math::VRand()
Returns a random vector with length of 1

VRandCone
static FVector Math::VRandCone(	
FVector 	DDir,
float32 	HorizontalConeHalfAngleRad,
float32 	VerticalConeHalfAngleRad
)
Returns a random unit vector, uniformly distributed, within the specified cone ConeHalfAngleRad is the half-angle of cone, in radians.  Returns a normalized vector.

VRandCone
static FVector Math::VRandCone(	
FVector 	DDir,
float32 	ConeHalfAngleRad
)
RandPointInCircle
static FVector2D Math::RandPointInCircle(	
float32 	Radius
)
Get a random point on a unit circle, evenly spread across the circumference.

GetReflectionVector
static FVector Math::GetReflectionVector(	
FVector 	Direction,
FVector 	SurfaceNormal
)
Given a direction vector and a surface normal, returns the vector reflected across the surface normal.  Produces a result like shining a laser at a mirror!

Parameters
Direction
FVector
Direction vector the ray is coming from.

SurfaceNormal
FVector
A normal of the surface the ray should be reflected on.

Returns
Reflected vector.

MakePulsatingValue
static float32 Math::MakePulsatingValue(	
float 	InCurrentTime,		
float32 	InPulsesPerSecond,		
float32 	InPhase	 = 	0.0f
)
Simple function to create a pulsating scalar value

Parameters
InCurrentTime
float
Current absolute time

InPulsesPerSecond
float32
How many full pulses per second?

InPhase
float32
Optional phase amount, between 0.0 and 1.0 (to synchronize pulses)

Returns
Pulsating value (0.0-1.0)

IsNearlyEqual
static bool Math::IsNearlyEqual(	
float 	A,		
float 	B,		
float 	ErrorTolerance	 = 	SMALL_NUMBER
)
IsNearlyEqual
static bool Math::IsNearlyEqual(	
float32 	A,		
float32 	B,		
float32 	ErrorTolerance	 = 	SMALL_NUMBER
)
IsNearlyZero
static bool Math::IsNearlyZero(	
float 	Value,		
float 	ErrorTolerance	 = 	SMALL_NUMBER
)
IsNearlyZero
static bool Math::IsNearlyZero(	
float32 	Value,		
float32 	ErrorTolerance	 = 	SMALL_NUMBER
)
IsPowerOfTwo
static bool Math::IsPowerOfTwo(	
int 	Value
)
SmoothStep
static float Math::SmoothStep(	
float 	A,
float 	B,
float 	X
)
Returns a smooth Hermite interpolation between 0 and 1 for the value X (where X ranges between A and B) Clamped to 0 for X <= A and 1 for X >= B.

Parameters
A
float
Minimum value of X

B
float
Maximum value of X

X
float
Parameter

Returns
Smoothed value between 0 and 1

SmoothStep
static float32 Math::SmoothStep(	
float32 	A,
float32 	B,
float32 	X
)
Returns a smooth Hermite interpolation between 0 and 1 for the value X (where X ranges between A and B) Clamped to 0 for X <= A and 1 for X >= B.

Parameters
A
float32
Minimum value of X

B
float32
Maximum value of X

X
float32
Parameter

Returns
Smoothed value between 0 and 1

Clamp
static float Math::Clamp(	
float 	X,
float 	Min,
float 	Max
)
Clamp
static float32 Math::Clamp(	
float32 	X,
float32 	Min,
float32 	Max
)
Clamp
static int Math::Clamp(	
int 	X,
int 	Min,
int 	Max
)
Wrap
static float Math::Wrap(	
float 	X,
float 	Min,
float 	Max
)
Wrap
static float32 Math::Wrap(	
float32 	X,
float32 	Min,
float32 	Max
)
Wrap
static int Math::Wrap(	
int 	X,
int 	Min,
int 	Max
)
SinCos
static void Math::SinCos(	
float32& 	ScalarSin,
float32& 	ScalarCos,
float32 	Value
)
SinCos
static void Math::SinCos(	
float& 	ScalarSin,
float& 	ScalarCos,
float 	Value
)
FastAsin
static float Math::FastAsin(	
float 	Value
)
FastAsin
static float32 Math::FastAsin(	
float32 	Value
)
RadiansToDegrees
static float Math::RadiansToDegrees(	
const 	float& 	RadVal
)
DegreesToRadians
static float Math::DegreesToRadians(	
const 	float& 	DegVal
)
RadiansToDegrees
static float32 Math::RadiansToDegrees(	
const 	float32& 	RadVal
)
DegreesToRadians
static float32 Math::DegreesToRadians(	
const 	float32& 	DegVal
)
ClampAngle
static float32 Math::ClampAngle(	
float32 	AngleDegrees,
float32 	MinAngleDegrees,
float32 	MaxAngleDegrees
)
FindDeltaAngleDegrees
static float Math::FindDeltaAngleDegrees(	
float 	A1,
float 	A2
)
FindDeltaAngleRadians
static float Math::FindDeltaAngleRadians(	
float 	A1,
float 	A2
)
FindDeltaAngleDegrees
static float32 Math::FindDeltaAngleDegrees(	
float32 	A1,
float32 	A2
)
FindDeltaAngleRadians
static float32 Math::FindDeltaAngleRadians(	
float32 	A1,
float32 	A2
)
UnwindDegrees
static float Math::UnwindDegrees(	
float 	A
)
Utility to ensure angle is between +/- 180 degrees by unwinding.

UnwindRadians
static float Math::UnwindRadians(	
float 	A
)
Utility to ensure angle is between +/- 180 degrees by unwinding.

UnwindDegrees
static float32 Math::UnwindDegrees(	
float32 	A
)
Utility to ensure angle is between +/- 180 degrees by unwinding.

UnwindRadians
static float32 Math::UnwindRadians(	
float32 	A
)
Utility to ensure angle is between +/- 180 degrees by unwinding.

LerpStable
static float Math::LerpStable(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
LerpStable
static float32 Math::LerpStable(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
Lerp
static float Math::Lerp(	
const 	float& 	A,
const 	float& 	B,
const 	float& 	Alpha
)
Lerp
static float32 Math::Lerp(	
const 	float32& 	A,
const 	float32& 	B,
const 	float32& 	Alpha
)
Lerp
static FVector Math::Lerp(	
FVector 	A,
FVector 	B,
const 	float& 	Alpha
)
Lerp
static FVector2D Math::Lerp(	
FVector2D 	A,
FVector2D 	B,
const 	float& 	Alpha
)
Lerp
static FVector3f Math::Lerp(	
FVector3f 	A,
FVector3f 	B,
const 	float32& 	Alpha
)
Lerp
static FVector2f Math::Lerp(	
FVector2f 	A,
FVector2f 	B,
const 	float32& 	Alpha
)
VLerp
static FVector Math::VLerp(	
FVector 	A,
FVector 	B,
FVector 	Alpha
)
Lerp
static FLinearColor Math::Lerp(	
FLinearColor 	A,
FLinearColor 	B,
const 	float32& 	Alpha
)
IsWithin
static bool Math::IsWithin(	
const 	float& 	TestValue,
const 	float& 	MinValue,
const 	float& 	MaxValue
)
IsWithin
static bool Math::IsWithin(	
const 	float32& 	TestValue,
const 	float32& 	MinValue,
const 	float32& 	MaxValue
)
IsWithin
static bool Math::IsWithin(	
const 	int& 	TestValue,
const 	int& 	MinValue,
const 	int& 	MaxValue
)
IsWithinInclusive
static bool Math::IsWithinInclusive(	
const 	float& 	TestValue,
const 	float& 	MinValue,
const 	float& 	MaxValue
)
IsWithinInclusive
static bool Math::IsWithinInclusive(	
const 	float32& 	TestValue,
const 	float32& 	MinValue,
const 	float32& 	MaxValue
)
IsWithinInclusive
static bool Math::IsWithinInclusive(	
const 	int& 	TestValue,
const 	int& 	MinValue,
const 	int& 	MaxValue
)
CubicInterp
static FVector Math::CubicInterp(	
FVector 	Point0,
FVector 	Tangent0,
FVector 	Point1,
FVector 	Tangent1,
const 	float& 	Alpha
)
CubicInterp
static FQuat Math::CubicInterp(	
FQuat 	Point0,
FQuat 	Tangent0,
FQuat 	Point1,
FQuat 	Tangent1,
const 	float& 	Alpha
)
CubicInterp
static FVector Math::CubicInterp(	
FVector 	Point0,
FVector 	Tangent0,
FVector 	Point1,
FVector 	Tangent1,
const 	float32& 	Alpha
)
CubicInterp
static FQuat Math::CubicInterp(	
FQuat 	Point0,
FQuat 	Tangent0,
FQuat 	Point1,
FQuat 	Tangent1,
const 	float32& 	Alpha
)
CubicInterp
static FVector3f Math::CubicInterp(	
FVector3f 	Point0,
FVector3f 	Tangent0,
FVector3f 	Point1,
FVector3f 	Tangent1,
const 	float32& 	Alpha
)
CubicInterp
static FQuat4f Math::CubicInterp(	
FQuat4f 	Point0,
FQuat4f 	Tangent0,
FQuat4f 	Point1,
FQuat4f 	Tangent1,
const 	float32& 	Alpha
)
CubicInterpDerivative
static FVector Math::CubicInterpDerivative(	
FVector 	Point0,
FVector 	Tangent0,
FVector 	Point1,
FVector 	Tangent1,
const 	float& 	Alpha
)
CubicInterpDerivative
static FRotator Math::CubicInterpDerivative(	
FRotator 	Point0,
FRotator 	Tangent0,
FRotator 	Point1,
FRotator 	Tangent1,
const 	float& 	Alpha
)
CubicInterpDerivative
static FVector Math::CubicInterpDerivative(	
FVector 	Point0,
FVector 	Tangent0,
FVector 	Point1,
FVector 	Tangent1,
const 	float32& 	Alpha
)
CubicInterpDerivative
static FRotator Math::CubicInterpDerivative(	
FRotator 	Point0,
FRotator 	Tangent0,
FRotator 	Point1,
FRotator 	Tangent1,
const 	float32& 	Alpha
)
CubicInterpDerivative
static FVector3f Math::CubicInterpDerivative(	
FVector3f 	Point0,
FVector3f 	Tangent0,
FVector3f 	Point1,
FVector3f 	Tangent1,
const 	float32& 	Alpha
)
CubicInterpDerivative
static FRotator3f Math::CubicInterpDerivative(	
FRotator3f 	Point0,
FRotator3f 	Tangent0,
FRotator3f 	Point1,
FRotator3f 	Tangent1,
const 	float32& 	Alpha
)
VInterpNormalRotationTo
static FVector Math::VInterpNormalRotationTo(	
FVector 	Current,
FVector 	Target,
float32 	DeltaTime,
float32 	RotationSpeedDegrees
)
VInterpConstantTo
static FVector Math::VInterpConstantTo(	
FVector 	Current,
FVector 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
VInterpTo
static FVector Math::VInterpTo(	
FVector 	Current,
FVector 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
RInterpConstantTo
static FRotator Math::RInterpConstantTo(	
FRotator 	Current,
FRotator 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
RInterpTo
static FRotator Math::RInterpTo(	
FRotator 	Current,
FRotator 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
RotatorFromAxisAndAngle
static FRotator Math::RotatorFromAxisAndAngle(	
FVector 	Axis,
float32 	Angle
)
LerpShortestPath
static FRotator Math::LerpShortestPath(	
FRotator 	A,
FRotator 	B,
float 	Alpha
)
Lerp between two rotators along the shortest path between them. Uses a quaternion slerp internally.

RInterpShortestPathTo
static FRotator Math::RInterpShortestPathTo(	
FRotator 	Current,
FRotator 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
Interp between two rotators along the shortest path between them. Uses a quaternion interp internally.

RInterpConstantShortestPathTo
static FRotator Math::RInterpConstantShortestPathTo(	
FRotator 	Current,
FRotator 	Target,
float32 	DeltaTime,
float32 	InterpSpeedDegrees
)
Interp with constant speed between two rotators along the shortest path between them. Uses a quaternion interp internally.

QInterpConstantTo
static FQuat Math::QInterpConstantTo(	
FQuat 	Current,
FQuat 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
QInterpTo
static FQuat Math::QInterpTo(	
FQuat 	Current,
FQuat 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
QInterpConstantTo
static FQuat4f Math::QInterpConstantTo(	
FQuat4f 	Current,
FQuat4f 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
QInterpTo
static FQuat4f Math::QInterpTo(	
FQuat4f 	Current,
FQuat4f 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
FInterpConstantTo
static float32 Math::FInterpConstantTo(	
float32 	Current,
float32 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
FInterpTo
static float32 Math::FInterpTo(	
float32 	Current,
float32 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
FInterpConstantTo
static float Math::FInterpConstantTo(	
float 	Current,
float 	Target,
float 	DeltaTime,
float 	InterpSpeed
)
FInterpTo
static float Math::FInterpTo(	
float 	Current,
float 	Target,
float 	DeltaTime,
float 	InterpSpeed
)
CInterpTo
static FLinearColor Math::CInterpTo(	
FLinearColor 	Current,
FLinearColor 	Target,
float32 	DeltaTime,
float32 	InterpSpeed
)
SphereAABBIntersection
static bool Math::SphereAABBIntersection(	
FVector 	SphereCenter,
float 	RadiusSquared,
FBox 	AABB
)
SphereAABBIntersection
static bool Math::SphereAABBIntersection(	
FSphere 	Sphere,
FBox 	AABB
)
SphereAABBIntersection
static bool Math::SphereAABBIntersection(	
FVector3f 	SphereCenter,
float32 	RadiusSquared,
FBox3f 	AABB
)
SphereAABBIntersection
static bool Math::SphereAABBIntersection(	
FSphere3f 	Sphere,
FBox3f 	AABB
)
LinePlaneIntersection
static FVector Math::LinePlaneIntersection(	
FVector 	Point1,
FVector 	Point2,
FVector 	PlaneOrigin,
FVector 	PlaneNormal
)
LinePlaneIntersection
static FVector3f Math::LinePlaneIntersection(	
FVector3f 	Point1,
FVector3f 	Point2,
FVector3f 	PlaneOrigin,
FVector3f 	PlaneNormal
)
LineSphereIntersection
static bool Math::LineSphereIntersection(	
FVector3f 	Start,
FVector3f 	Dir,
float32 	Length,
FVector3f 	Origin,
float32 	Radius
)
LineSphereIntersection
static bool Math::LineSphereIntersection(	
FVector 	Start,
FVector 	Dir,
float 	Length,
FVector 	Origin,
float 	Radius
)
ClosestPointOnLine
static FVector Math::ClosestPointOnLine(	
FVector 	LineStart,
FVector 	LineEnd,
FVector 	Point
)
ClosestPointOnInfiniteLine
static FVector Math::ClosestPointOnInfiniteLine(	
FVector 	LineStart,
FVector 	LineEnd,
FVector 	Point
)
ComputeBoundingSphereForCone
static FSphere Math::ComputeBoundingSphereForCone(	
FVector 	ConeOrigin,
FVector 	ConeDirection,
float 	ConeRadius,
float 	CosConeAngle,
float 	SinConeAngle
)
ComputeBoundingSphereForCone
static FSphere3f Math::ComputeBoundingSphereForCone(	
FVector3f 	ConeOrigin,
FVector3f 	ConeDirection,
float32 	ConeRadius,
float32 	CosConeAngle,
float32 	SinConeAngle
)
TruncToInt
static int Math::TruncToInt(	
float 	F
)
TruncToInt
static int Math::TruncToInt(	
float32 	F
)
TruncToFloat
static float Math::TruncToFloat(	
float 	F
)
TruncToDouble
static float Math::TruncToDouble(	
float 	F
)
TruncToFloat
static float32 Math::TruncToFloat(	
float32 	F
)
RoundToInt
static int Math::RoundToInt(	
float 	F
)
RoundToInt
static int Math::RoundToInt(	
float32 	F
)
RoundToFloat
static float Math::RoundToFloat(	
float 	F
)
RoundToFloat
static float32 Math::RoundToFloat(	
float32 	F
)
RoundToDouble
static float Math::RoundToDouble(	
float 	F
)
FloorToInt
static int Math::FloorToInt(	
float 	F
)
FloorToInt
static int Math::FloorToInt(	
float32 	F
)
FloorToFloat
static float Math::FloorToFloat(	
float 	F
)
FloorToDouble
static float Math::FloorToDouble(	
float 	F
)
FloorToFloat
static float32 Math::FloorToFloat(	
float32 	F
)
CeilToInt
static int Math::CeilToInt(	
float 	F
)
CeilToInt
static int Math::CeilToInt(	
float32 	F
)
CeilToDouble
static float Math::CeilToDouble(	
float 	F
)
RandHelper
static int Math::RandHelper(	
int 	Max
)
CeilToFloat
static float32 Math::CeilToFloat(	
float32 	F
)
IsNaN
static bool Math::IsNaN(	
float 	F
)
IsFinite
static bool Math::IsFinite(	
float 	F
)
InvSqrt
static float Math::InvSqrt(	
float 	F
)
InvSqrtEst
static float Math::InvSqrtEst(	
float 	F
)
Fractional
static float Math::Fractional(	
float 	Value
)
Frac
static float Math::Frac(	
float 	Value
)
IsNaN
static bool Math::IsNaN(	
float32 	F
)
IsFinite
static bool Math::IsFinite(	
float32 	F
)
InvSqrt
static float32 Math::InvSqrt(	
float32 	F
)
InvSqrtEst
static float32 Math::InvSqrtEst(	
float32 	F
)
Fractional
static float32 Math::Fractional(	
float32 	Value
)
Frac
static float32 Math::Frac(	
float32 	Value
)
Modf
static float Math::Modf(	
float 	InValue,
float& 	OutIntPart
)
Modf
static float32 Math::Modf(	
float32 	InValue,
float32& 	OutIntPart
)
Exp
static float Math::Exp(	
float 	Value
)
Exp2
static float Math::Exp2(	
float 	Value
)
Loge
static float Math::Loge(	
float 	Value
)
Log2
static float Math::Log2(	
float 	Value
)
LogX
static float Math::LogX(	
float 	Base,
float 	Value
)
Fmod
static float Math::Fmod(	
float 	X,
float 	Y
)
Sin
static float Math::Sin(	
float 	Value
)
Asin
static float Math::Asin(	
float 	Value
)
Sinh
static float Math::Sinh(	
float 	Value
)
Cos
static float Math::Cos(	
float 	Value
)
Acos
static float Math::Acos(	
float 	Value
)
Tan
static float Math::Tan(	
float 	Value
)
Atan
static float Math::Atan(	
float 	Value
)
Atan2
static float Math::Atan2(	
float 	Y,
float 	X
)
Sqrt
static float Math::Sqrt(	
float 	Value
)
Pow
static float Math::Pow(	
float 	A,
float 	B
)
Exp
static float32 Math::Exp(	
float32 	Value
)
Exp2
static float32 Math::Exp2(	
float32 	Value
)
Loge
static float32 Math::Loge(	
float32 	Value
)
Log2
static float32 Math::Log2(	
float32 	Value
)
LogX
static float32 Math::LogX(	
float32 	Base,
float32 	Value
)
Fmod
static float32 Math::Fmod(	
float32 	X,
float32 	Y
)
Sin
static float32 Math::Sin(	
float32 	Value
)
Asin
static float32 Math::Asin(	
float32 	Value
)
Sinh
static float32 Math::Sinh(	
float32 	Value
)
Cos
static float32 Math::Cos(	
float32 	Value
)
Acos
static float32 Math::Acos(	
float32 	Value
)
Tan
static float32 Math::Tan(	
float32 	Value
)
Atan
static float32 Math::Atan(	
float32 	Value
)
Atan2
static float32 Math::Atan2(	
float32 	Y,
float32 	X
)
Sqrt
static float32 Math::Sqrt(	
float32 	Value
)
Pow
static float32 Math::Pow(	
float32 	A,
float32 	B
)
Rand
static int Math::Rand()
FRand
static float32 Math::FRand()
Abs
static float Math::Abs(	
float 	Value
)
Abs
static float32 Math::Abs(	
float32 	Value
)
Abs
static int Math::Abs(	
int 	Value
)
Sign
static float Math::Sign(	
float 	Value
)
Sign
static float32 Math::Sign(	
float32 	Value
)
Sign
static int Math::Sign(	
int 	Value
)
Min
static float Math::Min(	
float 	A,
float 	B
)
Min
static float32 Math::Min(	
float32 	A,
float32 	B
)
Min
static int Math::Min(	
int 	A,
int 	B
)
Max3
static float Math::Max3(	
float 	A,
float 	B,
float 	C
)
Max3
static float32 Math::Max3(	
float32 	A,
float32 	B,
float32 	C
)
Max
static float Math::Max(	
float 	A,
float 	B
)
Max
static float32 Math::Max(	
float32 	A,
float32 	B
)
Max
static int Math::Max(	
int 	A,
int 	B
)
Square
static float Math::Square(	
float 	Value
)
Square
static float32 Math::Square(	
float32 	Value
)
Square
static int Math::Square(	
int 	Value
)
GetMappedRangeValueClamped
static float Math::GetMappedRangeValueClamped(	
FVector2D 	InputRange,
FVector2D 	OutputRange,
float 	Value
)
GetMappedRangeValueUnclamped
static float Math::GetMappedRangeValueUnclamped(	
FVector2D 	InputRange,
FVector2D 	OutputRange,
float 	Value
)
GetMappedRangeValueClamped
static float32 Math::GetMappedRangeValueClamped(	
FVector2f 	InputRange,
FVector2f 	OutputRange,
float32 	Value
)
GetMappedRangeValueUnclamped
static float32 Math::GetMappedRangeValueUnclamped(	
FVector2f 	InputRange,
FVector2f 	OutputRange,
float32 	Value
)
PerlinNoise1D
static float32 Math::PerlinNoise1D(	
float32 	X
)
Generates a 1D Perlin noise from the given value.  Returns a continuous random value between -1.0 and 1.0.

Returns
Perlin noise in the range of -1.0 to 1.0

PerlinNoise2D
static float32 Math::PerlinNoise2D(	
FVector2D 	Location
)
Generates a 1D Perlin noise sample at the given location.  Returns a continuous random value between -1.0 and 1.0.

Parameters
Location
FVector2D
Where to sample

Returns
Perlin noise in the range of -1.0 to 1.0

PerlinNoise3D
static float32 Math::PerlinNoise3D(	
FVector 	Location
)
Generates a 3D Perlin noise sample at the given location.  Returns a continuous random value between -1.0 and 1.0.

Parameters
Location
FVector
Where to sample

Returns
Perlin noise in the range of -1.0 to 1.0

GridSnap
static float Math::GridSnap(	
float 	Location,
float 	Grid
)
GridSnap
static float32 Math::GridSnap(	
float32 	Location,
float32 	Grid
)
SegmentIntersection2D
static bool Math::SegmentIntersection2D(	
FVector 	SegmentStartA,
FVector 	SegmentEndA,
FVector 	SegmentStartB,
FVector 	SegmentEndB,
FVector& 	out_IntersectionPoint
)
Returns true if there is an intersection between the segment specified by SegmentStartA and SegmentEndA, and the segment specified by SegmentStartB and SegmentEndB, in 2D space. If there is an intersection, the point is placed in out_IntersectionPoint

Parameters
SegmentStartA
FVector
start point of first segment

SegmentEndA
FVector
end point of first segment

SegmentStartB
FVector
start point of second segment

SegmentEndB
FVector
end point of second segment

out_IntersectionPoint
FVector&
out var for the intersection point (if any)

Returns
true if intersection occurred

FloatSpringInterp
static float32 Math::FloatSpringInterp(	
float32 	Current,		
float32 	Target,		
FFloatSpringState& 	SpringState,		
float32 	Stiffness,		
float32 	CriticalDampingFactor,		
float32 	DeltaTime,		
float32 	Mass	 = 	1.f
)
Uses a simple spring model to interpolate a float32 from Current to Target.

Parameters
Current
float32
Current value

Target
float32
Target value

SpringState
FFloatSpringState&
Data related to spring model (velocity, error, etc..) - Create a unique variable per spring

Stiffness
float32
How stiff the spring model is (more stiffness means more oscillation around the target value)

CriticalDampingFactor
float32
How much damping to apply to the spring (0 means no damping, 1 means critically damped which means no oscillation)

Mass
float32
Multiplier that acts like mass on a spring

EaseIn
static float Math::EaseIn(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha,
float 	Exp
)
EaseOut
static float Math::EaseOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha,
float 	Exp
)
EaseInOut
static float Math::EaseInOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha,
float 	Exp
)
SinusoidalIn
static float Math::SinusoidalIn(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
SinusoidalOut
static float Math::SinusoidalOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
SinusoidalInOut
static float Math::SinusoidalInOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
ExpoIn
static float Math::ExpoIn(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
ExpoOut
static float Math::ExpoOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
ExpoInOut
static float Math::ExpoInOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
CircularIn
static float Math::CircularIn(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
CircularOut
static float Math::CircularOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
CircularInOut
static float Math::CircularInOut(	
const 	float& 	A,
const 	float& 	B,
float 	Alpha
)
EaseIn
static float32 Math::EaseIn(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha,
float32 	Exp
)
EaseOut
static float32 Math::EaseOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha,
float32 	Exp
)
EaseInOut
static float32 Math::EaseInOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha,
float32 	Exp
)
SinusoidalIn
static float32 Math::SinusoidalIn(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
SinusoidalOut
static float32 Math::SinusoidalOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
SinusoidalInOut
static float32 Math::SinusoidalInOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
ExpoIn
static float32 Math::ExpoIn(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
ExpoOut
static float32 Math::ExpoOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
ExpoInOut
static float32 Math::ExpoInOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
CircularIn
static float32 Math::CircularIn(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
CircularOut
static float32 Math::CircularOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
CircularInOut
static float32 Math::CircularInOut(	
const 	float32& 	A,
const 	float32& 	B,
float32 	Alpha
)
EaseIn
static FVector Math::EaseIn(	
FVector 	A,
FVector 	B,
float32 	Alpha,
float32 	Exp
)
EaseOut
static FVector Math::EaseOut(	
FVector 	A,
FVector 	B,
float32 	Alpha,
float32 	Exp
)
EaseInOut
static FVector Math::EaseInOut(	
FVector 	A,
FVector 	B,
float32 	Alpha,
float32 	Exp
)
SinusoidalIn
static FVector Math::SinusoidalIn(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
SinusoidalOut
static FVector Math::SinusoidalOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
SinusoidalInOut
static FVector Math::SinusoidalInOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
ExpoIn
static FVector Math::ExpoIn(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
ExpoOut
static FVector Math::ExpoOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
ExpoInOut
static FVector Math::ExpoInOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
CircularIn
static FVector Math::CircularIn(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
CircularOut
static FVector Math::CircularOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
CircularInOut
static FVector Math::CircularInOut(	
FVector 	A,
FVector 	B,
float32 	Alpha
)
IsPointInBox
static bool Math::IsPointInBox(	
FVector 	Point,
FVector 	BoxOrigin,
FVector 	BoxExtent
)
IsPointInBoxWithTransform
static bool Math::IsPointInBoxWithTransform(	
FVector 	Point,
FTransform 	BoxWorldTransform,
FVector 	BoxExtent
)
FindNearestPointsOnLineSegments
static void Math::FindNearestPointsOnLineSegments(	
FVector 	Segment1Start,
FVector 	Segment1End,
FVector 	Segment2Start,
FVector 	Segment2End,
FVector& 	Segment1Point,
FVector& 	Segment2Point
)
NormalizeToRange
static float Math::NormalizeToRange(	
float 	Value,
float 	RangeMin,
float 	RangeMax
)

Gameplay
Gameplay
Static Variables
PlatformName
static const FString Gameplay::PlatformName
Accessibility
AnnounceAccessibleString
static void Gameplay::AnnounceAccessibleString(	
FString 	AnnouncementString
)
If accessibility is enabled, have the platform announce a string to the player.  These announcements can be interrupted by system accessibiliity announcements or other accessibility announcement requests.  This should be used judiciously as flooding a player with announcements can be overrwhelming and confusing.  Try to make announcements concise and clear.  NOTE: Currently only supported on Win10, Mac, iOS

Actor
GetAllActorsWithInterface
static void Gameplay::GetAllActorsWithInterface(	
TSubclassOf<UInterface> 	Interface,
TArray<AActor>& 	OutActors
)
Find all Actors in the world with the specified interface.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
Interface
TSubclassOf<UInterface>
Interface to find. Must be specified or result array will be empty.

OutActors
TArray<AActor>&
Output array of Actors of the specified interface.

GetAllActorsWithTag
static void Gameplay::GetAllActorsWithTag(	
FName 	Tag,
TArray<AActor>& 	OutActors
)
Find all Actors in the world with the specified tag.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
Tag
FName
Tag to find. Must be specified or result array will be empty.

OutActors
TArray<AActor>&
Output array of Actors of the specified tag.

FindNearestActor
static AActor Gameplay::FindNearestActor(	
FVector 	Origin,
TArray<AActor> 	ActorsToCheck,
float32& 	Distance
)
Returns an Actor nearest to Origin from ActorsToCheck array.

Parameters
Origin
FVector
World Location from which the distance is measured.

ActorsToCheck
TArray<AActor>
Array of Actors to examine and return Actor nearest to Origin.

Distance
float32&
Distance from Origin to the returned Actor.

Returns
Nearest Actor.

GetAllActorsOfClassWithTag
static void Gameplay::GetAllActorsOfClassWithTag(	
TSubclassOf<AActor> 	ActorClass,
FName 	Tag,
TArray<AActor>& 	OutActors
)
Find all Actors in the world of the specified class with the specified tag.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
ActorClass
TSubclassOf<AActor>
Class of Actor to find. Must be specified or result array will be empty.

Tag
FName
Tag to find. Must be specified or result array will be empty.

OutActors
TArray<AActor>&
Output array of Actors of the specified tag.

GetAllActorsOfClass
static void Gameplay::GetAllActorsOfClass(	
TSubclassOf<AActor> 	ActorClass,
TArray<AActor>& 	OutActors
)
Find all Actors in the world of the specified class.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
ActorClass
TSubclassOf<AActor>
Class of Actor to find. Must be specified or result array will be empty.

OutActors
TArray<AActor>&
Output array of Actors of the specified class.

GetActorOfClass
static AActor Gameplay::GetActorOfClass(	
TSubclassOf<AActor> 	ActorClass
)
Find the first Actor in the world of the specified class.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
ActorClass
TSubclassOf<AActor>
Class of Actor to find. Must be specified or result will be empty.

Returns
Actor of the specified class.

Audio
AreAnyListenersWithinRange
static bool Gameplay::AreAnyListenersWithinRange(	
FVector 	Location,
float32 	MaximumRange
)
Determines if any audio listeners are within range of the specified location

Parameters
Location
FVector
The location from which test if a listener is in range

MaximumRange
float32
The distance away from Location to test if any listener is within

SpawnSound2D
static UAudioComponent Gameplay::SpawnSound2D(
USoundBase 	Sound,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
bool 	bPersistAcrossLevelTransition	 = 	false,
bool 	bAutoDestroy	 = 	true
)
This function allows users to create Audio Components with settings specifically for non-spatialized, non-distance-attenuated sounds. Audio Components created using this function by default will not have Spatialization applied. Sound instances will begin playing upon spawning this Audio Component.

Not Replicated.

Parameters
Sound
USoundBase
Sound to play.

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the sound to begin playback at

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
An audio component to manipulate the spawned sound

PlaySound2D
static void Gameplay::PlaySound2D(	
USoundBase 	Sound,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
const 	AActor 	OwningActor	 = 	nullptr,
bool 	bIsUISound	 = 	true
)
Plays a sound directly with no attenuation, perfect for UI sounds.

Fire and Forget.

Not Replicated.

Parameters
Sound
USoundBase
Sound to play.

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the sound to begin playback at

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

OwningActor
const AActor
The actor to use as the "owner" for concurrency settings purposes. Allows PlaySound calls to do a concurrency limit per owner.

bIsUISound
bool
True if sound is UI related, else false

GetMaxAudioChannelCount
static int Gameplay::GetMaxAudioChannelCount()
Retrieves the max voice count currently used by the audio engine.

SetBaseSoundMix
static void Gameplay::SetBaseSoundMix(	
USoundMix 	InSoundMix
)
Set the sound mix of the audio system for special EQing

PlayDialogueAtLocation
static void Gameplay::PlayDialogueAtLocation(	
UDialogueWave 	Dialogue,		
FDialogueContext 	Context,		
FVector 	Location,		
FRotator 	Rotation,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr
)
Plays a dialogue at the given location. This is a fire and forget sound and does not travel with any actor.  Replication is also not handled at this point.

Parameters
Dialogue
UDialogueWave
dialogue to play

Context
FDialogueContext
context the dialogue is to play in

Location
FVector
World position to play dialogue at

Rotation
FRotator
World rotation to play dialogue at

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the dialogue to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

UnRetainAllSoundsInSoundClass
static void Gameplay::UnRetainAllSoundsInSoundClass(	
USoundClass 	InSoundClass
)
Iterate through all sound waves and releases handles to retained chunks. (If the chunk is not being played it will be up for eviction)

SetGlobalPitchModulation
static void Gameplay::SetGlobalPitchModulation(	
float32 	PitchModulation,
float32 	TimeSec
)
Sets a global pitch modulation scalar that will apply to all non-UI sounds

Fire and Forget.

Not Replicated.

Parameters
PitchModulation
float32
A pitch modulation value to globally set.

TimeSec
float32
A time value to linearly interpolate the global modulation pitch over from it's current value.

GetClosestListenerLocation
static bool Gameplay::GetClosestListenerLocation(	
FVector 	Location,
float32 	MaximumRange,
bool 	bAllowAttenuationOverride,
FVector& 	ListenerPosition
)
Finds and returns the position of the closest listener to the specified location

Parameters
Location
FVector
The location from which we'd like to find the closest listener, in world space.

MaximumRange
float32
The maximum distance away from Location that a listener can be.

bAllowAttenuationOverride
bool
True for the adjusted listener position (if attenuation override is set), false for the raw listener position (for panning)

ListenerPosition
FVector&
[Out] The position of the closest listener in world space, if found.

Returns
true if we've successfully found a listener within MaximumRange of Location, otherwise false.

SpawnSoundAtLocation
static UAudioComponent Gameplay::SpawnSoundAtLocation(
USoundBase 	Sound,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( ),
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
Spawns a sound at the given location. This does not travel with any actor. Replication is also not handled at this point.

Parameters
Sound
USoundBase
sound to play

Location
FVector
World position to play sound at

Rotation
FRotator
World rotation to play sound at

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the sound to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
An audio component to manipulate the spawned sound

SetSoundClassDistanceScale
static void Gameplay::SetSoundClassDistanceScale(	
USoundClass 	SoundClass,		
float32 	DistanceAttenuationScale,		
float32 	TimeSec	 = 	0.000000
)
Linearly interpolates the attenuation distance scale value from it's current attenuation distance override value (1.0f it not overridden) to its new attenuation distance override, over the given amount of time

Fire and Forget.

Not Replicated.

Parameters
SoundClass
USoundClass
Sound class to to use to set the attenuation distance scale on.

DistanceAttenuationScale
float32
A scalar for the attenuation distance used for computing distance attenuation.

TimeSec
float32
A time value to linearly interpolate from the current distance attenuation scale value to the new value.

SetGlobalListenerFocusParameters
static void Gameplay::SetGlobalListenerFocusParameters(	
float32 	FocusAzimuthScale	 = 	1.000000,
float32 	NonFocusAzimuthScale	 = 	1.000000,
float32 	FocusDistanceScale	 = 	1.000000,
float32 	NonFocusDistanceScale	 = 	1.000000,
float32 	FocusVolumeScale	 = 	1.000000,
float32 	NonFocusVolumeScale	 = 	1.000000,
float32 	FocusPriorityScale	 = 	1.000000,
float32 	NonFocusPriorityScale	 = 	1.000000
)
Sets the global listener focus parameters, which will scale focus behavior of sounds based on their focus azimuth settings in their attenuation settings.

Fire and Forget.

Not Replicated.

Parameters
FocusAzimuthScale
float32
An angle scale value used to scale the azimuth angle that defines where sounds are in-focus.

FocusDistanceScale
float32
A distance scale value to use for sounds which are in-focus. Values < 1.0 will reduce perceived distance to sounds, values > 1.0 will increase perceived distance to in-focus sounds.

NonFocusDistanceScale
float32
A distance scale value to use for sounds which are out-of-focus. Values < 1.0 will reduce perceived distance to sounds, values > 1.0 will increase perceived distance to in-focus sounds.

FocusPriorityScale
float32
A priority scale value (> 0.0) to use for sounds which are in-focus. Values < 1.0 will reduce the priority of in-focus sounds, values > 1.0 will increase the priority of in-focus sounds.

NonFocusPriorityScale
float32
A priority scale value (> 0.0) to use for sounds which are out-of-focus. Values < 1.0 will reduce the priority of sounds out-of-focus sounds, values > 1.0 will increase the priority of out-of-focus sounds.

GetCurrentReverbEffect
static UReverbEffect Gameplay::GetCurrentReverbEffect()
Returns the highest priority reverb settings currently active from any source (Audio Volumes or manual settings).

ClearSoundMixClassOverride
static void Gameplay::ClearSoundMixClassOverride(	
USoundMix 	InSoundMixModifier,		
USoundClass 	InSoundClass,		
float32 	FadeOutTime	 = 	1.000000
)
Clears any existing override of the Sound Class Adjuster in the given Sound Mix

Parameters
InSoundMixModifier
USoundMix
The sound mix to modify.

InSoundClass
USoundClass
The sound class in the sound mix to clear overrides from.

FadeOutTime
float32
The interpolation time to use to go from the current sound class adjuster override values to the non-override values.

PrimeAllSoundsInSoundClass
static void Gameplay::PrimeAllSoundsInSoundClass(	
USoundClass 	InSoundClass
)
Primes the sound waves in the given USoundClass, caching the first chunk of streamed audio.

PrimeSound
static void Gameplay::PrimeSound(	
USoundBase 	InSound
)
Primes the sound, caching the first chunk of streamed audio.

PlayDialogue2D
static void Gameplay::PlayDialogue2D(	
UDialogueWave 	Dialogue,		
FDialogueContext 	Context,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000
)
Plays a dialogue directly with no attenuation, perfect for UI.

Fire and Forget.

Not Replicated.

Parameters
Dialogue
UDialogueWave
dialogue to play

Context
FDialogueContext
context the dialogue is to play in

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the dialogue to begin playback at

DeactivateReverbEffect
static void Gameplay::DeactivateReverbEffect(	
FName 	TagName
)
Deactivates a Reverb Effect that was applied outside of an Audio Volume

Parameters
TagName
FName
Tag associated with Reverb Effect to remove

ClearSoundMixModifiers
static void Gameplay::ClearSoundMixModifiers()
Clear all sound mix modifiers from the audio system

SpawnSoundAttached
static UAudioComponent Gameplay::SpawnSoundAttached(
USoundBase 	Sound,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName	 = 	NAME_None,
FVector 	Location	 = 	FVector ( ),
FRotator 	Rotation	 = 	FRotator ( ),
EAttachLocation 	LocationType	 = 	EAttachLocation :: KeepRelativeOffset,
bool 	bStopWhenAttachedToDestroyed	 = 	false,
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
This function allows users to create and play Audio Components attached to a specific Scene Component.  Useful for spatialized and/or distance-attenuated sounds that need to follow another object in space.

Parameters
Sound
USoundBase
sound to play

AttachPointName
FName
Optional named point within the AttachComponent to play the sound at

Location
FVector
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world position that will be translated to a relative offset

Rotation
FRotator
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a relative offset

LocationType
EAttachLocation
Specifies whether Location is a relative offset or an absolute world position

bStopWhenAttachedToDestroyed
bool
Specifies whether the sound should stop playing when the owner of the attach to component is destroyed.

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the sound to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
An audio component to manipulate the spawned sound

SetMaxAudioChannelsScaled
static void Gameplay::SetMaxAudioChannelsScaled(	
float32 	MaxChannelCountScale
)
Sets the max number of voices (also known as "channels") dynamically by percentage. E.g. if you want to temporarily reduce voice count by 50%, use 0.50. Later, you can return to the original max voice count by using 1.0.

Parameters
MaxChannelCountScale
float32
The percentage of the original voice count to set the max number of voices to

SetSoundMixClassOverride
static void Gameplay::SetSoundMixClassOverride(	
USoundMix 	InSoundMixModifier,		
USoundClass 	InSoundClass,		
float32 	Volume	 = 	1.000000,
float32 	Pitch	 = 	1.000000,
float32 	FadeInTime	 = 	1.000000,
bool 	bApplyToChildren	 = 	true
)
Overrides the sound class adjuster in the given sound mix. If the sound class does not exist in the input sound mix, the sound class adjuster will be added to the list of active sound mix modifiers.

Parameters
InSoundMixModifier
USoundMix
The sound mix to modify.

InSoundClass
USoundClass
The sound class to override (or add) in the sound mix.

Volume
float32
The volume scale to set the sound class adjuster to.

Pitch
float32
The pitch scale to set the sound class adjuster to.

FadeInTime
float32
The interpolation time to use to go from the current sound class adjuster values to the new values.

bApplyToChildren
bool
Whether or not to apply this override to the sound class' children or to just the specified sound class.

PushSoundMixModifier
static void Gameplay::PushSoundMixModifier(	
USoundMix 	InSoundMixModifier
)
Push a sound mix modifier onto the audio system

Parameters
InSoundMixModifier
USoundMix
The Sound Mix Modifier to add to the system

CreateSound2D
static UAudioComponent Gameplay::CreateSound2D(
USoundBase 	Sound,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
bool 	bPersistAcrossLevelTransition	 = 	false,
bool 	bAutoDestroy	 = 	true
)
This function allows users to create Audio Components in advance of playback with settings specifically for non-spatialized, non-distance-attenuated sounds. Audio Components created using this function by default will not have Spatialization applied.

Parameters
Sound
USoundBase
Sound to create.

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far into the sound to begin playback at

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping), or whether it can be reactivated

Returns
An audio component to manipulate the created sound

ActivateReverbEffect
static void Gameplay::ActivateReverbEffect(	
UReverbEffect 	ReverbEffect,		
FName 	TagName,		
float32 	Priority	 = 	0.000000,
float32 	Volume	 = 	0.500000,
float32 	FadeTime	 = 	2.000000
)
Activates a Reverb Effect without the need for an Audio Volume

Parameters
ReverbEffect
UReverbEffect
Reverb Effect to use

TagName
FName
Tag to associate with Reverb Effect

Priority
float32
Priority of the Reverb Effect

Volume
float32
Volume level of Reverb Effect

FadeTime
float32
Time before Reverb Effect is fully active

SpawnDialogueAttached
static UAudioComponent Gameplay::SpawnDialogueAttached(
UDialogueWave 	Dialogue,		
FDialogueContext 	Context,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName	 = 	NAME_None,
FVector 	Location	 = 	FVector ( ),
FRotator 	Rotation	 = 	FRotator ( ),
EAttachLocation 	LocationType	 = 	EAttachLocation :: KeepRelativeOffset,
bool 	bStopWhenAttachedToDestroyed	 = 	false,
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
Spawns a DialogueWave, a special type of Asset that requires Context data in order to resolve a specific SoundBase, which is then passed on to the new Audio Component. This function allows users to create and play Audio Components attached to a specific Scene Component. Useful for spatialized and/or distance-attenuated dialogue that needs to follow another object in space.

Parameters
Dialogue
UDialogueWave
dialogue to play

Context
FDialogueContext
context the dialogue is to play in

AttachPointName
FName
Optional named point within the AttachComponent to play the sound at

Location
FVector
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world position that will be translated to a relative offset

Rotation
FRotator
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a relative offset

LocationType
EAttachLocation
Specifies whether Location is a relative offset or an absolute world position

bStopWhenAttachedToDestroyed
bool
Specifies whether the sound should stop playing when the owner its attached to is destroyed.

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the dialogue to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
Audio Component to manipulate the playing dialogue with

SpawnDialogue2D
static UAudioComponent Gameplay::SpawnDialogue2D(	
UDialogueWave 	Dialogue,		
FDialogueContext 	Context,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
bool 	bAutoDestroy	 = 	true
)
Spawns a DialogueWave, a special type of Asset that requires Context data in order to resolve a specific SoundBase, which is then passed on to the new Audio Component. Audio Components created using this function by default will not have Spatialization applied. Sound instances will begin playing upon spawning this Audio Component.

Not Replicated.

Parameters
Dialogue
UDialogueWave
dialogue to play

Context
FDialogueContext
context the dialogue is to play in

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the dialogue to begin playback at

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
An audio component to manipulate the spawned sound

SpawnDialogueAtLocation
static UAudioComponent Gameplay::SpawnDialogueAtLocation(
UDialogueWave 	Dialogue,		
FDialogueContext 	Context,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( ),
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
Spawns a DialogueWave, a special type of Asset that requires Context data in order to resolve a specific SoundBase, which is then passed on to the new Audio Component. This function allows users to create and play Audio Components at a specific World Location and Rotation. Useful for spatialized and/or distance-attenuated dialogue.

Parameters
Dialogue
UDialogueWave
Dialogue to play

Context
FDialogueContext
Context the dialogue is to play in

Location
FVector
World position to play dialogue at

Rotation
FRotator
World rotation to play dialogue at

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far into the dialogue to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

bAutoDestroy
bool
Whether the returned audio component will be automatically cleaned up when the sound finishes (by completing or stopping) or whether it can be reactivated

Returns
Audio Component to manipulate the playing dialogue with

PopSoundMixModifier
static void Gameplay::PopSoundMixModifier(	
USoundMix 	InSoundMixModifier
)
Pop a sound mix modifier from the audio system

Parameters
InSoundMixModifier
USoundMix
The Sound Mix Modifier to remove from the system

PlaySoundAtLocation
static void Gameplay::PlaySoundAtLocation(
USoundBase 	Sound,		
FVector 	Location,		
FRotator 	Rotation,		
float32 	VolumeMultiplier	 = 	1.000000,
float32 	PitchMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
USoundAttenuation 	AttenuationSettings	 = 	nullptr,
USoundConcurrency 	ConcurrencySettings	 = 	nullptr,
const 	AActor 	OwningActor	 = 	nullptr,
UInitialActiveSoundParams 	InitialParams	 = 	nullptr
)
Plays a sound at the given location. This is a fire and forget sound and does not travel with any actor.  Replication is also not handled at this point.

Parameters
Sound
USoundBase
sound to play

Location
FVector
World position to play sound at

Rotation
FRotator
World rotation to play sound at

VolumeMultiplier
float32
A linear scalar multiplied with the volume, in order to make the sound louder or softer.

PitchMultiplier
float32
A linear scalar multiplied with the pitch.

StartTime
float32
How far in to the sound to begin playback at

AttenuationSettings
USoundAttenuation
Override attenuation settings package to play sound with

ConcurrencySettings
USoundConcurrency
Override concurrency settings package to play sound with

OwningActor
const AActor
The actor to use as the "owner" for concurrency settings purposes. Allows PlaySound calls to do a concurrency limit per owner.

Audio|Subtitles
SetSubtitlesEnabled
static void Gameplay::SetSubtitlesEnabled(	
bool 	bEnabled
)
Will set subtitles to be enabled or disabled.

Parameters
bEnabled
bool
will enable subtitle drawing if true, disable if false.

AreSubtitlesEnabled
static bool Gameplay::AreSubtitlesEnabled()
Returns whether or not subtitles are currently enabled.

Returns
true if subtitles are enabled.

Camera
GetViewProjectionMatrix
static void Gameplay::GetViewProjectionMatrix(	
FMinimalViewInfo 	DesiredView,
FMatrix& 	ViewMatrix,
FMatrix& 	ProjectionMatrix,
FMatrix& 	ViewProjectionMatrix
)
Returns the View Matrix, Projection Matrix and the View x Projection Matrix for a given view

Parameters
DesiredView
FMinimalViewInfo
FMinimalViewInfo struct for a camera.

ViewMatrix
FMatrix&
(out) Corresponding View Matrix

ProjectionMatrix
FMatrix&
(out) Corresponding Projection Matrix

ViewProjectionMatrix
FMatrix&
(out) Corresponding View x Projection Matrix

DeprojectScreenToWorld
static bool Gameplay::DeprojectScreenToWorld(	
const 	APlayerController 	Player,
FVector2D 	ScreenPosition,
FVector& 	WorldPosition,
FVector& 	WorldDirection
)
Transforms the given 2D screen space coordinate into a 3D world-space point and direction.

Parameters
Player
const APlayerController
Deproject using this player's view.

ScreenPosition
FVector2D
2D screen space to deproject.

WorldPosition
FVector&
(out) Corresponding 3D position in world space.

WorldDirection
FVector&
(out) World space direction vector away from the camera at the given 2d point.

ProjectWorldToScreen
static bool Gameplay::ProjectWorldToScreen(	
const 	APlayerController 	Player,		
FVector 	WorldPosition,		
FVector2D& 	ScreenPosition,		
bool 	bPlayerViewportRelative	 = 	false
)
Transforms the given 3D world-space point into a its 2D screen space coordinate.

Parameters
Player
const APlayerController
Project using this player's view.

WorldPosition
FVector
World position to project.

ScreenPosition
FVector2D&
(out) Corresponding 2D position in screen space

bPlayerViewportRelative
bool
Should this be relative to the player viewport subregion (useful when using player attached widgets in split screen)

PlayWorldCameraShake
static void Gameplay::PlayWorldCameraShake(
TSubclassOf<UCameraShakeBase> 	Shake,		
FVector 	Epicenter,		
float32 	InnerRadius,		
float32 	OuterRadius,		
float32 	Falloff	 = 	1.000000,
bool 	bOrientShakeTowardsEpicenter	 = 	false
)
Plays an in-world camera shake that affects all nearby local players, with distance-based attenuation. Does not replicate.

Parameters
WorldContextObject	
Object that we can obtain a world context from

Shake
TSubclassOf<UCameraShakeBase>
Camera shake asset to use

Epicenter
FVector
location to place the effect in world space

InnerRadius
float32
Cameras inside this radius are ignored

OuterRadius
float32
Cameras outside of InnerRadius and inside this are effected

Falloff
float32
Affects falloff of effect as it nears OuterRadius

bOrientShakeTowardsEpicenter
bool
Changes the rotation of shake to point towards epicenter instead of forward

Collision
GetActorArrayBounds
static void Gameplay::GetActorArrayBounds(	
TArray<AActor> 	Actors,
bool 	bOnlyCollidingComponents,
FVector& 	Center,
FVector& 	BoxExtent
)
Bind the bounds of an array of Actors

BreakHitResult
static void Gameplay::BreakHitResult(	
FHitResult 	Hit,
bool& 	bBlockingHit,
bool& 	bInitialOverlap,
float32& 	Time,
float32& 	Distance,
FVector& 	Location,
FVector& 	ImpactPoint,
FVector& 	Normal,
FVector& 	ImpactNormal,
UPhysicalMaterial& 	PhysMat,
AActor& 	HitActor,
UPrimitiveComponent& 	HitComponent,
FName& 	HitBoneName,
FName& 	BoneName,
int& 	HitItem,
int& 	ElementIndex,
int& 	FaceIndex,
FVector& 	TraceStart,
FVector& 	TraceEnd
)
Extracts data from a HitResult.

Parameters
Hit
FHitResult
The source HitResult.

bBlockingHit
bool&
True if there was a blocking hit, false otherwise.

bInitialOverlap
bool&
True if the hit started in an initial overlap. In this case some other values should be interpreted differently. Time will be 0, ImpactPoint will equal Location, and normals will be equal and indicate a depenetration vector.

Time
float32&
'Time' of impact along trace direction ranging from [0.0 to 1.0) if there is a hit, indicating time between start and end. Equals 1.0 if there is no hit.

Distance
float32&
The distance from the TraceStart to the Location in world space. This value is 0 if there was an initial overlap (trace started inside another colliding object).

Location
FVector&
Location of the hit in world space. If this was a swept shape test, this is the location where we can place the shape in the world where it will not penetrate.

ImpactPoint
FVector&
Location of the actual contact point of the trace shape with the surface of the hit object. Equal to Location in the case of an initial overlap.

Normal
FVector&
Normal of the hit in world space, for the object that was swept (e.g. for a sphere trace this points towards the sphere's center). Equal to ImpactNormal for line tests.

ImpactNormal
FVector&
Normal of the hit in world space, for the object that was hit by the sweep.

PhysMat
UPhysicalMaterial&
Physical material that was hit. Must set bReturnPhysicalMaterial to true in the query params for this to be returned.

HitActor
AActor&
Actor hit by the trace.

HitComponent
UPrimitiveComponent&
PrimitiveComponent hit by the trace.

HitBoneName
FName&
Name of the bone hit (valid only if we hit a skeletal mesh).

BoneName
FName&
Name of the trace bone hit (valid only if we hit a skeletal mesh).

HitItem
int&
Primitive-specific data recording which item in the primitive was hit

ElementIndex
int&
If colliding with a primitive with multiple parts, index of the part that was hit.

FaceIndex
int&
If colliding with trimesh or landscape, index of face that was hit.

GetSurfaceType
static EPhysicalSurface Gameplay::GetSurfaceType(	
FHitResult 	Hit
)
Returns the EPhysicalSurface type of the given Hit.  To edit surface type for your project, use ProjectSettings/Physics/PhysicalSurface section

FindCollisionUV
static bool Gameplay::FindCollisionUV(	
FHitResult 	Hit,
int 	UVChannel,
FVector2D& 	UV
)
Try and find the UV for a collision impact. Note this ONLY works if 'Support UV From Hit Results' is enabled in Physics Settings.

MakeHitResult
static FHitResult Gameplay::MakeHitResult(	
bool 	bBlockingHit,
bool 	bInitialOverlap,
float32 	Time,
float32 	Distance,
FVector 	Location,
FVector 	ImpactPoint,
FVector 	Normal,
FVector 	ImpactNormal,
UPhysicalMaterial 	PhysMat,
AActor 	HitActor,
UPrimitiveComponent 	HitComponent,
FName 	HitBoneName,
FName 	BoneName,
int 	HitItem,
int 	ElementIndex,
int 	FaceIndex,
FVector 	TraceStart,
FVector 	TraceEnd
)
Create a HitResult struct

Parameters
bBlockingHit
bool
True if there was a blocking hit, false otherwise.

bInitialOverlap
bool
True if the hit started in an initial overlap. In this case some other values should be interpreted differently. Time will be 0, ImpactPoint will equal Location, and normals will be equal and indicate a depenetration vector.

Time
float32
'Time' of impact along trace direction ranging from [0.0 to 1.0) if there is a hit, indicating time between start and end. Equals 1.0 if there is no hit.

Distance
float32
The distance from the TraceStart to the Location in world space. This value is 0 if there was an initial overlap (trace started inside another colliding object).

Location
FVector
Location of the hit in world space. If this was a swept shape test, this is the location where we can place the shape in the world where it will not penetrate.

ImpactPoint
FVector
Location of the actual contact point of the trace shape with the surface of the hit object. Equal to Location in the case of an initial overlap.

Normal
FVector
Normal of the hit in world space, for the object that was swept (e.g. for a sphere trace this points towards the sphere's center). Equal to ImpactNormal for line tests.

ImpactNormal
FVector
Normal of the hit in world space, for the object that was hit by the sweep.

PhysMat
UPhysicalMaterial
Physical material that was hit. Must set bReturnPhysicalMaterial to true in the query params for this to be returned.

HitActor
AActor
Actor hit by the trace.

HitComponent
UPrimitiveComponent
PrimitiveComponent hit by the trace.

HitBoneName
FName
Name of the bone hit (valid only if we hit a skeletal mesh).

BoneName
FName
Name of the trace bone hit (valid only if we hit a skeletal mesh).

HitItem
int
Primitive-specific data recording which item in the primitive was hit

ElementIndex
int
If colliding with a primitive with multiple parts, index of the part that was hit.

FaceIndex
int
If colliding with trimesh or landscape, index of face that was hit.

Effects
SpawnEmitterAttached
static UParticleSystemComponent Gameplay::SpawnEmitterAttached(
UParticleSystem 	EmitterTemplate,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName	 = 	NAME_None,
FVector 	Location	 = 	FVector ( ),
FRotator 	Rotation	 = 	FRotator ( ),
FVector 	Scale	 = 	FVector ( 1.000000 , 1.000000 , 1.000000 ),
EAttachLocation 	LocationType	 = 	EAttachLocation :: KeepRelativeOffset,
bool 	bAutoDestroy	 = 	true,
EPSCPoolMethod 	PoolingMethod	 = 	EPSCPoolMethod :: None,
bool 	bAutoActivate	 = 	true
)
Plays the specified effect attached to and following the specified component. The system will go away when the effect is complete. Does not replicate.

Parameters
EmitterTemplate
UParticleSystem
particle system to create

AttachPointName
FName
Optional named point within the AttachComponent to spawn the emitter at

Location
FVector
Depending on the value of LocationType this is either a relative offset from the attach component/point or an absolute world location that will be translated to a relative offset (if LocationType is KeepWorldPosition).

Rotation
FRotator
Depending on the value of LocationType this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a relative offset (if LocationType is KeepWorldPosition).

Scale
FVector
Depending on the value of LocationType this is either a relative scale from the attach component or an absolute world scale that will be translated to a relative scale (if LocationType is KeepWorldPosition).

LocationType
EAttachLocation
Specifies whether Location is a relative offset or an absolute world position

bAutoDestroy
bool
Whether the component will automatically be destroyed when the particle system completes playing or whether it can be reactivated

PoolingMethod
EPSCPoolMethod
Method used for pooling this component. Defaults to none.

bAutoActivate
bool
Whether the component will be automatically activated on creation.

SpawnEmitterAtLocation
static UParticleSystemComponent Gameplay::SpawnEmitterAtLocation(
UParticleSystem 	EmitterTemplate,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( ),
FVector 	Scale	 = 	FVector ( 1.000000 , 1.000000 , 1.000000 ),
bool 	bAutoDestroy	 = 	true,
EPSCPoolMethod 	PoolingMethod	 = 	EPSCPoolMethod :: None,
bool 	bAutoActivateSystem	 = 	true
)
Plays the specified effect at the given location and rotation, fire and forget. The system will go away when the effect is complete. Does not replicate.

Parameters
WorldContextObject	
Object that we can obtain a world context from

EmitterTemplate
UParticleSystem
particle system to create

Location
FVector
location to place the effect in world space

Rotation
FRotator
rotation to place the effect in world space

Scale
FVector
scale to create the effect at

bAutoDestroy
bool
Whether the component will automatically be destroyed when the particle system completes playing or whether it can be reactivated

PoolingMethod
EPSCPoolMethod
Method used for pooling this component. Defaults to none.

Foliage
GrassOverlappingSphereCount
static int Gameplay::GrassOverlappingSphereCount(	
const 	UStaticMesh 	StaticMesh,
FVector 	CenterPosition,
float32 	Radius
)
Counts how many grass foliage instances overlap a given sphere.

Parameters
CenterPosition
FVector
The center position of the sphere.

Radius
float32
The radius of the sphere.

Returns
Number of foliage instances with their mesh set to Mesh that overlap the sphere.

ForceFeedback
SpawnForceFeedbackAtLocation
static UForceFeedbackComponent Gameplay::SpawnForceFeedbackAtLocation(
UForceFeedbackEffect 	ForceFeedbackEffect,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( ),
bool 	bLooping	 = 	false,
float32 	IntensityMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
UForceFeedbackAttenuation 	AttenuationSettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
Plays a force feedback effect at the given location. This is a fire and forget effect and does not travel with any actor. Replication is also not handled at this point.

Parameters
ForceFeedbackEffect
UForceFeedbackEffect
effect to play

Location
FVector
World position to center the effect at

Rotation
FRotator
World rotation to center the effect at

IntensityMultiplier
float32
Intensity multiplier

StartTime
float32
How far in to the feedback effect to begin playback at

AttenuationSettings
UForceFeedbackAttenuation
Override attenuation settings package to play effect with

bAutoDestroy
bool
Whether the returned force feedback component will be automatically cleaned up when the feedback pattern finishes (by completing or stopping) or whether it can be reactivated

Returns
Force Feedback Component to manipulate the playing feedback effect with

SpawnForceFeedbackAttached
static UForceFeedbackComponent Gameplay::SpawnForceFeedbackAttached(
UForceFeedbackEffect 	ForceFeedbackEffect,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName	 = 	NAME_None,
FVector 	Location	 = 	FVector ( ),
FRotator 	Rotation	 = 	FRotator ( ),
EAttachLocation 	LocationType	 = 	EAttachLocation :: KeepRelativeOffset,
bool 	bStopWhenAttachedToDestroyed	 = 	false,
bool 	bLooping	 = 	false,
float32 	IntensityMultiplier	 = 	1.000000,
float32 	StartTime	 = 	0.000000,
UForceFeedbackAttenuation 	AttenuationSettings	 = 	nullptr,
bool 	bAutoDestroy	 = 	true
)
Plays a force feedback effect attached to and following the specified component. This is a fire and forget effect. Replication is also not handled at this point.

Parameters
ForceFeedbackEffect
UForceFeedbackEffect
effect to play

AttachPointName
FName
Optional named point within the AttachComponent to attach to

Location
FVector
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world position that will be translated to a relative offset

Rotation
FRotator
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a relative offset

LocationType
EAttachLocation
Specifies whether Location is a relative offset or an absolute world position

bStopWhenAttachedToDestroyed
bool
Specifies whether the feedback effect should stop playing when the owner of the attach to component is destroyed.

IntensityMultiplier
float32
Intensity multiplier

StartTime
float32
How far in to the feedback effect to begin playback at

AttenuationSettings
UForceFeedbackAttenuation
Override attenuation settings package to play effect with

bAutoDestroy
bool
Whether the returned force feedback component will be automatically cleaned up when the feedback patern finishes (by completing or stopping) or whether it can be reactivated

Returns
Force Feedback Component to manipulate the playing feedback effect with

Game
LoadStreamLevel
static void Gameplay::LoadStreamLevel(	
FName 	LevelName,
bool 	bMakeVisibleAfterLoad,
bool 	bShouldBlockOnLoad,
FLatentActionInfo 	LatentInfo
)
Stream the level (by Name); Calling again before it finishes has no effect

LoadStreamLevelBySoftObjectPtr
static void Gameplay::LoadStreamLevelBySoftObjectPtr(
const 	TSoftObjectPtr<UWorld> 	Level,
bool 	bMakeVisibleAfterLoad,
bool 	bShouldBlockOnLoad,
FLatentActionInfo 	LatentInfo
)
Stream the level (by Object Reference); Calling again before it finishes has no effect

FlushLevelStreaming
static void Gameplay::FlushLevelStreaming()
Flushes level streaming in blocking fashion and returns when all sub-levels are loaded / visible / hidden

OpenLevel
static void Gameplay::OpenLevel(	
FName 	LevelName,		
bool 	bAbsolute	 = 	true,
FString 	Options	 = 	""
)
Travel to another level

Parameters
LevelName
FName
the level to open

bAbsolute
bool
if true options are reset, if false options are carried over from current level

Options
FString
a string of options to use for the travel URL

OpenLevelBySoftObjectPtr
static void Gameplay::OpenLevelBySoftObjectPtr(	
const 	TSoftObjectPtr<UWorld> 	Level,		
bool 	bAbsolute	 = 	true,
FString 	Options	 = 	""
)
Travel to another level

Parameters
Level
const TSoftObjectPtr<UWorld>
the level to open

bAbsolute
bool
if true options are reset, if false options are carried over from current level

Options
FString
a string of options to use for the travel URL

GetNumLocalPlayerControllers
static int Gameplay::GetNumLocalPlayerControllers()
Returns the number of fully initialized local players, this will be 0 on dedicated servers.  Indexes up to this can be used as PlayerIndex parameters for the following functions, and you are guaranteed to get a local player controller.

GetNumPlayerControllers
static int Gameplay::GetNumPlayerControllers()
Returns the total number of available player controllers, including remote players when called on a server.  Indexes up to this can be used as PlayerIndex parameters for the following functions.

GetNumPlayerStates
static int Gameplay::GetNumPlayerStates()
Returns the number of active player states, there is one player state for every connected player even if they are a remote client.  Indexes up to this can be use as PlayerStateIndex parameters for other functions.

GetPlatformName
static FString Gameplay::GetPlatformName()
Returns the string name of the current platform, to perform different behavior based on platform.  (Platform names include Windows, Mac, IOS, Android, PS4, XboxOne, Linux)

Blueprint_PredictProjectilePath_Advanced
static bool Gameplay::Blueprint_PredictProjectilePath_Advanced(
FPredictProjectilePathParams 	PredictParams,
FPredictProjectilePathResult& 	PredictResult
)
Predict the arc of a virtual projectile affected by gravity with collision checks along the arc.  Returns true if it hit something.

Parameters
PredictParams
FPredictProjectilePathParams
Input params to the trace (start location, velocity, time to simulate, etc).

PredictResult
FPredictProjectilePathResult&
Output result of the trace (Hit result, array of location/velocity/times for each trace step, etc).

Returns
True if hit something along the path (if tracing with collision).

GetPlayerCameraManager
static APlayerCameraManager Gameplay::GetPlayerCameraManager(	
int 	PlayerIndex
)
Returns the camera manager for the Player Controller at the specified player index.  This will not include remote clients with no player controller.

Parameters
PlayerIndex
int
Index in the player controller list, starting first with local players and then available remote ones

GetPlayerCharacter
static ACharacter Gameplay::GetPlayerCharacter(	
int 	PlayerIndex
)
Returns the pawn for the player controller at the specified player index, will return null if the pawn is not a character.  This will not include characters of remote clients with no available player controller, you can iterate the PlayerStates list for that.

Parameters
PlayerIndex
int
Index in the player controller list, starting first with local players and then available remote ones

GetPlayerController
static APlayerController Gameplay::GetPlayerController(	
int 	PlayerIndex
)
Returns the player controller found while iterating through the local and available remote player controllers.  On a network client, this will only include local players as remote player controllers are not available.  The index will be consistent as long as no new players join or leave, but it will not be the same across different clients and servers.

Parameters
PlayerIndex
int
Index in the player controller list, starting first with local players and then available remote ones

GetPlayerControllerFromID
static APlayerController Gameplay::GetPlayerControllerFromID(	
int 	ControllerID
)
Returns the player controller with the specified physical controller ID. This only works for local players.

Parameters
ControllerID
int
Physical controller ID, the same value returned from Get Player Controller ID

GetPlayerControllerID
static int Gameplay::GetPlayerControllerID(	
APlayerController 	Player
)
Gets what physical controller ID a player is using. This only works for local player controllers.

Parameters
Player
APlayerController
The player controller of the player to get the ID of

Returns
The ID of the passed in player. -1 if there is no physical controller assigned to the passed in player

GetPlayerPawn
static APawn Gameplay::GetPlayerPawn(	
int 	PlayerIndex
)
Returns the pawn for the player controller at the specified player index.  This will not include pawns of remote clients with no available player controller, you can use the player states list for that.

Parameters
PlayerIndex
int
Index in the player controller list, starting first with local players and then available remote ones

GetPlayerState
static APlayerState Gameplay::GetPlayerState(	
int 	PlayerStateIndex
)
Returns the player state at the given index in the game state's PlayerArray.  This will work on both the client and server and the index will be consistent.  After initial replication, all clients and the server will have access to PlayerStates for all connected players.

Parameters
PlayerStateIndex
int
Index into the game state's PlayerArray

GetStreamingLevel
static ULevelStreaming Gameplay::GetStreamingLevel(	
FName 	PackageName
)
Returns level streaming object with specified level package name

GetCurrentLevelName
static FString Gameplay::GetCurrentLevelName(	
bool 	bRemovePrefixString	 = 	true
)
Get the name of the currently-open level.

Parameters
bRemovePrefixString
bool
remove any streaming- or editor- added prefixes from the level name.

EnableLiveStreaming
static void Gameplay::EnableLiveStreaming(	
bool 	Enable
)
Toggle live DVR streaming.

Parameters
Enable
bool
If true enable streaming, otherwise disable.

CreatePlayer
static APlayerController Gameplay::CreatePlayer(	
int 	ControllerId	 = 	- 1,
bool 	bSpawnPlayerController	 = 	true
)
Create a new local player for this game, for cases like local multiplayer.

Parameters
ControllerId
int
The ID of the physical controller that the should control the newly created player. A value of -1 specifies to use the next available ID

bSpawnPlayerController
bool
Whether a player controller should be spawned immediately for this player. If false a player controller will not be created automatically until transition to the next map.

Returns
The created player controller if one is created.

GetWorldOriginLocation
static FIntVector Gameplay::GetWorldOriginLocation()
Returns world origin current location.

GetGameInstance
static UGameInstance Gameplay::GetGameInstance()
Returns the game instance object

IsGamePaused
static bool Gameplay::IsGamePaused()
Returns the game's paused state

Returns
Whether the game is currently paused or not

UnloadStreamLevelBySoftObjectPtr
static void Gameplay::UnloadStreamLevelBySoftObjectPtr(
const 	TSoftObjectPtr<UWorld> 	Level,
FLatentActionInfo 	LatentInfo,
bool 	bShouldBlockOnUnload
)
Unload a streamed in level (by Object Reference)

Blueprint_PredictProjectilePath_ByObjectType
static bool Gameplay::Blueprint_PredictProjectilePath_ByObjectType(
FHitResult& 	OutHit,		
TArray<FVector>& 	OutPathPositions,		
FVector& 	OutLastTraceDestination,		
FVector 	StartPos,		
FVector 	LaunchVelocity,		
bool 	bTracePath,		
float32 	ProjectileRadius,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
float32 	DrawDebugTime,		
float32 	SimFrequency	 = 	15.000000,
float32 	MaxSimTime	 = 	2.000000,
float32 	OverrideGravityZ	 = 	0.000000
)
Predict the arc of a virtual projectile affected by gravity with collision checks along the arc. Returns a list of positions of the simulated arc and the destination reached by the simulation.  Returns true if it hit something.

Parameters
OutHit
FHitResult&
Predicted hit result, if the projectile will hit something

OutPathPositions
TArray<FVector>&
Predicted projectile path. Ordered series of positions from StartPos to the end. Includes location at point of impact if it hit something.

OutLastTraceDestination
FVector&
Goal position of the final trace it did. Will not be in the path if there is a hit.

StartPos
FVector
First start trace location

LaunchVelocity
FVector
Velocity the "virtual projectile" is launched at

bTracePath
bool
Trace along the entire path to look for blocking hits

ProjectileRadius
float32
Radius of the virtual projectile to sweep against the environment

ObjectTypes
TArray<EObjectTypeQuery>
ObjectTypes to trace against, if bTracePath is true.

bTraceComplex
bool
Use TraceComplex (trace against triangles not primitives)

ActorsToIgnore
TArray<AActor>
Actors to exclude from the traces

DrawDebugType
EDrawDebugTrace
Debug type (one-frame, duration, persistent)

DrawDebugTime
float32
Duration of debug lines (only relevant for DrawDebugType::Duration)

SimFrequency
float32
Determines size of each sub-step in the simulation (chopping up MaxSimTime)

MaxSimTime
float32
Maximum simulation time for the virtual projectile.

OverrideGravityZ
float32
Optional override of Gravity (if 0, uses WorldGravityZ)

Returns
True if hit something along the path if tracing for collision.

CancelAsyncLoading
static void Gameplay::CancelAsyncLoading()
Cancels all currently queued streaming packages

BlueprintSuggestProjectileVelocity
static bool Gameplay::BlueprintSuggestProjectileVelocity(
FVector& 	TossVelocity,
FVector 	StartLocation,
FVector 	EndLocation,
float32 	LaunchSpeed,
float32 	OverrideGravityZ,
ESuggestProjVelocityTraceOption 	TraceOption,
float32 	CollisionRadius,
bool 	bFavorHighArc,
bool 	bDrawDebug
)
Calculates an launch velocity for a projectile to hit a specified point.

Parameters
TossVelocity
FVector&
(output) Result launch velocity.

StartLocation
FVector
Intended launch location

EndLocation
FVector
Desired landing location

LaunchSpeed
float32
Desired launch speed

OverrideGravityZ
float32
Optional gravity override.  0 means "do not override".

TraceOption
ESuggestProjVelocityTraceOption
Controls whether or not to validate a clear path by tracing along the calculated arc

CollisionRadius
float32
Radius of the projectile (assumed spherical), used when tracing

bFavorHighArc
bool
If true and there are 2 valid solutions, will return the higher arc.  If false, will favor the lower arc.

bDrawDebug
bool
When true, a debug arc is drawn (red for an invalid arc, green for a valid arc)

Returns
Returns false if there is no valid solution or the valid solutions are blocked.  Returns true otherwise.

Blueprint_PredictProjectilePath_ByTraceChannel
static bool Gameplay::Blueprint_PredictProjectilePath_ByTraceChannel(
FHitResult& 	OutHit,		
TArray<FVector>& 	OutPathPositions,		
FVector& 	OutLastTraceDestination,		
FVector 	StartPos,		
FVector 	LaunchVelocity,		
bool 	bTracePath,		
float32 	ProjectileRadius,		
ECollisionChannel 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
float32 	DrawDebugTime,		
float32 	SimFrequency	 = 	15.000000,
float32 	MaxSimTime	 = 	2.000000,
float32 	OverrideGravityZ	 = 	0.000000
)
Predict the arc of a virtual projectile affected by gravity with collision checks along the arc. Returns a list of positions of the simulated arc and the destination reached by the simulation.  Returns true if it hit something (if tracing with collision).

Parameters
OutHit
FHitResult&
Predicted hit result, if the projectile will hit something

OutPathPositions
TArray<FVector>&
Predicted projectile path. Ordered series of positions from StartPos to the end. Includes location at point of impact if it hit something.

OutLastTraceDestination
FVector&
Goal position of the final trace it did. Will not be in the path if there is a hit.

StartPos
FVector
First start trace location

LaunchVelocity
FVector
Velocity the "virtual projectile" is launched at

bTracePath
bool
Trace along the entire path to look for blocking hits

ProjectileRadius
float32
Radius of the virtual projectile to sweep against the environment

TraceChannel
ECollisionChannel
TraceChannel to trace against, if bTracePath is true.

bTraceComplex
bool
Use TraceComplex (trace against triangles not primitives)

ActorsToIgnore
TArray<AActor>
Actors to exclude from the traces

DrawDebugType
EDrawDebugTrace
Debug type (one-frame, duration, persistent)

DrawDebugTime
float32
Duration of debug lines (only relevant for DrawDebugType::Duration)

SimFrequency
float32
Determines size of each sub-step in the simulation (chopping up MaxSimTime)

MaxSimTime
float32
Maximum simulation time for the virtual projectile.

OverrideGravityZ
float32
Optional override of Gravity (if 0, uses WorldGravityZ)

Returns
True if hit something along the path (if tracing with collision).

GetGameMode
static AGameModeBase Gameplay::GetGameMode()
Returns the current GameModeBase or Null if it can't be retrieved, such as on the client

GetGameState
static AGameStateBase Gameplay::GetGameState()
Returns the current GameStateBase or Null if it can't be retrieved

GetPlayerStateFromUniqueNetId
static APlayerState Gameplay::GetPlayerStateFromUniqueNetId(	
FUniqueNetIdRepl 	UniqueId
)
Returns the player state that matches the passed in online id, or null for an invalid one.  This will work on both the client and server for local and remote players.

Parameters
UniqueId
FUniqueNetIdRepl
The player's unique net/online id

RebaseLocalOriginOntoZero
static FVector Gameplay::RebaseLocalOriginOntoZero(	
FVector 	WorldLocation
)
Returns origin based position for local world location.

SetWorldOriginLocation
static void Gameplay::SetWorldOriginLocation(	
FIntVector 	NewLocation
)
Requests a new location for a world origin.

RebaseZeroOriginOntoLocal
static FVector Gameplay::RebaseZeroOriginOntoLocal(	
FVector 	WorldLocation
)
Returns local location for origin based position.

SuggestProjectileVelocity_CustomArc
static bool Gameplay::SuggestProjectileVelocity_CustomArc(	
FVector& 	OutLaunchVelocity,		
FVector 	StartPos,		
FVector 	EndPos,		
float32 	OverrideGravityZ	 = 	0.000000,
float32 	ArcParam	 = 	0.500000
)
Returns the launch velocity needed for a projectile at rest at StartPos to land on EndPos.  Assumes a medium arc (e.g. 45 deg on level ground). Projectile velocity is variable and unconstrained.  Does no tracing.

Parameters
OutLaunchVelocity
FVector&
Returns the launch velocity required to reach the EndPos

StartPos
FVector
Start position of the simulation

EndPos
FVector
Desired end location for the simulation

OverrideGravityZ
float32
Optional override of WorldGravityZ

ArcParam
float32
Change height of arc between 0.0-1.0 where 0.5 is the default medium arc, 0 is up, and 1 is directly toward EndPos.

SetPlayerControllerID
static void Gameplay::SetPlayerControllerID(	
APlayerController 	Player,
int 	ControllerId
)
Sets what physical controller ID a player should be using. This only works for local player controllers.

Parameters
Player
APlayerController
The player controller of the player to change the controller ID of

ControllerId
int
The controller ID to assign to this player

UnloadStreamLevel
static void Gameplay::UnloadStreamLevel(	
FName 	LevelName,
FLatentActionInfo 	LatentInfo,
bool 	bShouldBlockOnUnload
)
Unload a streamed in level (by Name)

RemovePlayer
static void Gameplay::RemovePlayer(	
APlayerController 	Player,
bool 	bDestroyPawn
)
Removes a local player from this game.

Parameters
Player
APlayerController
The player controller of the player to be removed

bDestroyPawn
bool
Whether the controlled pawn should be deleted as well

SetGamePaused
static bool Gameplay::SetGamePaused(	
bool 	bPaused
)
Sets the game's paused state

Parameters
bPaused
bool
Whether the game should be paused or not

Returns
Whether the game was successfully paused/unpaused

Game Options
GetIntOption
static int Gameplay::GetIntOption(	
FString 	Options,
FString 	Key,
int 	DefaultValue
)
Find an option in the options string and return it as an integer.

Parameters
Options
FString
The string containing the options.

Key
FString
The key to find the value of in Options.

Returns
The value associated with Key as an integer if Key found in Options string, otherwise DefaultValue.

GetKeyValue
static void Gameplay::GetKeyValue(	
FString 	Pair,
FString& 	Key,
FString& 	Value
)
Break up a key=value pair into its key and value.

Parameters
Pair
FString
The string containing a pair to split apart.

Key
FString&
(out) Key portion of Pair. If no = in string will be the same as Pair.

Value
FString&
(out) Value portion of Pair. If no = in string will be empty.

HasOption
static bool Gameplay::HasOption(	
FString 	Options,
FString 	InKey
)
Returns whether a key exists in an options string.

Parameters
Options
FString
The string containing the options.

Returns
Whether Key was found in Options.

ParseOption
static FString Gameplay::ParseOption(	
FString 	Options,
FString 	Key
)
Find an option in the options string and return it.

Parameters
Options
FString
The string containing the options.

Key
FString
The key to find the value of in Options.

Returns
The value associated with Key if Key found in Options string.

Game|Damage
ApplyDamage
static float32 Gameplay::ApplyDamage(	
AActor 	DamagedActor,
float32 	BaseDamage,
AController 	EventInstigator,
AActor 	DamageCauser,
TSubclassOf<UDamageType> 	DamageTypeClass
)
Hurts the specified actor with generic damage.

Parameters
DamagedActor
AActor
Actor that will be damaged.

BaseDamage
float32
The base damage to apply.

EventInstigator
AController
Controller that was responsible for causing this damage (e.g. player who shot the weapon)

DamageCauser
AActor
Actor that actually caused the damage (e.g. the grenade that exploded)

DamageTypeClass
TSubclassOf<UDamageType>
Class that describes the damage that was done.

Returns
Actual damage the ended up being applied to the actor.

ApplyRadialDamage
static bool Gameplay::ApplyRadialDamage(
float32 	BaseDamage,		
FVector 	Origin,		
float32 	DamageRadius,		
TSubclassOf<UDamageType> 	DamageTypeClass,		
TArray<AActor> 	IgnoreActors,		
AActor 	DamageCauser	 = 	nullptr,
AController 	InstigatedByController	 = 	nullptr,
bool 	bDoFullDamage	 = 	false,
ECollisionChannel 	DamagePreventionChannel	 = 	ECollisionChannel :: ECC_Visibility
)
Hurt locally authoritative actors within the radius. Will only hit components that block the Visibility channel.

Parameters
BaseDamage
float32
The base damage to apply, i.e. the damage at the origin.

Origin
FVector
Epicenter of the damage area.

DamageRadius
float32
Radius of the damage area, from Origin

DamageTypeClass
TSubclassOf<UDamageType>
Class that describes the damage that was done.

IgnoreActors
TArray<AActor>
List of Actors to ignore

DamageCauser
AActor
Actor that actually caused the damage (e.g. the grenade that exploded).  This actor will not be damaged and it will not block damage.

InstigatedByController
AController
Controller that was responsible for causing this damage (e.g. player who threw the grenade)

DamagePreventionChannel
ECollisionChannel
Damage will not be applied to victim if there is something between the origin and the victim which blocks traces on this channel

Returns
true if damage was applied to at least one actor.

ApplyPointDamage
static float32 Gameplay::ApplyPointDamage(	
AActor 	DamagedActor,
float32 	BaseDamage,
FVector 	HitFromDirection,
FHitResult 	HitInfo,
AController 	EventInstigator,
AActor 	DamageCauser,
TSubclassOf<UDamageType> 	DamageTypeClass
)
Hurts the specified actor with the specified impact.

Parameters
DamagedActor
AActor
Actor that will be damaged.

BaseDamage
float32
The base damage to apply.

HitFromDirection
FVector
Direction the hit came FROM

HitInfo
FHitResult
Collision or trace result that describes the hit

EventInstigator
AController
Controller that was responsible for causing this damage (e.g. player who shot the weapon)

DamageCauser
AActor
Actor that actually caused the damage (e.g. the grenade that exploded)

DamageTypeClass
TSubclassOf<UDamageType>
Class that describes the damage that was done.

Returns
Actual damage the ended up being applied to the actor.

ApplyRadialDamageWithFalloff
static bool Gameplay::ApplyRadialDamageWithFalloff(
float32 	BaseDamage,		
float32 	MinimumDamage,		
FVector 	Origin,		
float32 	DamageInnerRadius,		
float32 	DamageOuterRadius,		
float32 	DamageFalloff,		
TSubclassOf<UDamageType> 	DamageTypeClass,		
TArray<AActor> 	IgnoreActors,		
AActor 	DamageCauser	 = 	nullptr,
AController 	InstigatedByController	 = 	nullptr,
ECollisionChannel 	DamagePreventionChannel	 = 	ECollisionChannel :: ECC_Visibility
)
Hurt locally authoritative actors within the radius. Will only hit components that block the Visibility channel.

Parameters
BaseDamage
float32
The base damage to apply, i.e. the damage at the origin.

Origin
FVector
Epicenter of the damage area.

DamageInnerRadius
float32
Radius of the full damage area, from Origin

DamageOuterRadius
float32
Radius of the minimum damage area, from Origin

DamageFalloff
float32
Falloff exponent of damage from DamageInnerRadius to DamageOuterRadius

DamageTypeClass
TSubclassOf<UDamageType>
Class that describes the damage that was done.

IgnoreActors
TArray<AActor>
List of Actors to ignore

DamageCauser
AActor
Actor that actually caused the damage (e.g. the grenade that exploded)

InstigatedByController
AController
Controller that was responsible for causing this damage (e.g. player who threw the grenade)

DamagePreventionChannel
ECollisionChannel
Damage will not be applied to victim if there is something between the origin and the victim which blocks traces on this channel

Returns
true if damage was applied to at least one actor.

Rendering
SetEnableWorldRendering
static void Gameplay::SetEnableWorldRendering(	
bool 	bEnable
)
Enabled rendering of the world

Parameters
bEnable
bool
Whether the world should be rendered or not

GetEnableWorldRendering
static bool Gameplay::GetEnableWorldRendering()
Returns the world rendering state

Returns
Whether the world should be rendered or not

Rendering|Decal
SpawnDecalAtLocation
static UDecalComponent Gameplay::SpawnDecalAtLocation(
UMaterialInterface 	DecalMaterial,		
FVector 	DecalSize,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( - 90.000000 , 0.000000 , 0.000000 ),
float32 	LifeSpan	 = 	0.000000
)
Spawns a decal at the given location and rotation, fire and forget. Does not replicate.

Parameters
DecalMaterial
UMaterialInterface
decal's material

DecalSize
FVector
size of decal

Location
FVector
location to place the decal in world space

Rotation
FRotator
rotation to place the decal in world space

LifeSpan
float32
destroy decal component after time runs out (0 = infinite)

SpawnDecalAttached
static UDecalComponent Gameplay::SpawnDecalAttached(
UMaterialInterface 	DecalMaterial,		
FVector 	DecalSize,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName	 = 	NAME_None,
FVector 	Location	 = 	FVector ( ),
FRotator 	Rotation	 = 	FRotator ( ),
EAttachLocation 	LocationType	 = 	EAttachLocation :: KeepRelativeOffset,
float32 	LifeSpan	 = 	0.000000
)
Spawns a decal attached to and following the specified component. Does not replicate.

Parameters
DecalMaterial
UMaterialInterface
decal's material

DecalSize
FVector
size of decal

AttachPointName
FName
Optional named point within the AttachComponent to spawn the emitter at

Location
FVector
Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world position that will be translated to a relative offset

Rotation
FRotator
Depending on the value of LocationType this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a realative offset

LocationType
EAttachLocation
Specifies whether Location is a relative offset or an absolute world position

LifeSpan
float32
destroy decal component after time runs out (0 = infinite)

SaveGame
SaveGameToSlot
static bool Gameplay::SaveGameToSlot(	
USaveGame 	SaveGameObject,
FString 	SlotName,
int 	UserIndex
)
Save the contents of the SaveGameObject to a platform-specific save slot/file.  Note: This will write out all non-transient properties, the SaveGame property flag is not checked

Parameters
SaveGameObject
USaveGame
Object that contains data about the save game that we want to write out

SlotName
FString
Name of save game slot to save to.

UserIndex
int
For some platforms, master user index to identify the user doing the saving.

Returns
Whether we successfully saved this information

DoesSaveGameExist
static bool Gameplay::DoesSaveGameExist(	
FString 	SlotName,
int 	UserIndex
)
See if a save game exists with the specified name.

Parameters
SlotName
FString
Name of save game slot.

UserIndex
int
For some platforms, master user index to identify the user doing the saving.

CreateSaveGameObject
static USaveGame Gameplay::CreateSaveGameObject(	
TSubclassOf<USaveGame> 	SaveGameClass
)
Create a new, empty SaveGame object to set data on and then pass to SaveGameToSlot.

Parameters
SaveGameClass
TSubclassOf<USaveGame>
Class of SaveGame to create

Returns
New SaveGame object to write data to

LoadGameFromSlot
static USaveGame Gameplay::LoadGameFromSlot(	
FString 	SlotName,
int 	UserIndex
)
Load the contents from a given slot.

Parameters
SlotName
FString
Name of the save game slot to load from.

UserIndex
int
For some platforms, master user index to identify the user doing the loading.

Returns
Object containing loaded game state (nullptr if load fails)

DeleteGameInSlot
static bool Gameplay::DeleteGameInSlot(	
FString 	SlotName,
int 	UserIndex
)
Delete a save game in a particular slot.

Parameters
SlotName
FString
Name of save game slot to delete.

UserIndex
int
For some platforms, master user index to identify the user doing the deletion.

Returns
True if a file was actually able to be deleted. use DoesSaveGameExist to distinguish between delete failures and failure due to file not existing.

Transformation
GetActorArrayAverageLocation
static FVector Gameplay::GetActorArrayAverageLocation(	
TArray<AActor> 	Actors
)
Find the average location (centroid) of an array of Actors

Utilities
GetObjectClass
static UClass Gameplay::GetObjectClass(	
const 	UObject 	Object
)
Returns the class of a passed in Object, will always be valid if Object is not NULL

HasLaunchOption
static bool Gameplay::HasLaunchOption(	
FString 	OptionToCheck
)
Checks the commandline to see if the desired option was specified on the commandline (e.g. -demobuild)

Returns
True if the launch option was specified on the commandline, false otherwise

Utilities|Time
GetAudioTimeSeconds
static float32 Gameplay::GetAudioTimeSeconds()
Returns time in seconds since world was brought up for play, IS stopped when game pauses, NOT dilated/clamped.

GetWorldDeltaSeconds
static float32 Gameplay::GetWorldDeltaSeconds()
Returns the frame delta time in seconds, adjusted by time dilation.

GetUnpausedTimeSeconds
static float32 Gameplay::GetUnpausedTimeSeconds()
Returns time in seconds since world was brought up for play, adjusted by time dilation and IS NOT stopped when game pauses

GetAccurateRealTime
static void Gameplay::GetAccurateRealTime(	
int& 	Seconds,
float32& 	PartialSeconds
)
Returns time in seconds since the application was started. Unlike the other time functions this is accurate to the exact time this function is called instead of set once per frame.

SetGlobalTimeDilation
static void Gameplay::SetGlobalTimeDilation(	
float32 	TimeDilation
)
Sets the global time dilation.

Parameters
TimeDilation
float32
value to set the global time dilation to

GetGlobalTimeDilation
static float32 Gameplay::GetGlobalTimeDilation()
Gets the current global time dilation.

Returns
Current time dilation.

GetRealTimeSeconds
static float32 Gameplay::GetRealTimeSeconds()
Returns time in seconds since world was brought up for play, does NOT stop when game pauses, NOT dilated/clamped

GetTimeSeconds
static float32 Gameplay::GetTimeSeconds()
Returns time in seconds since world was brought up for play, adjusted by time dilation and IS stopped when game pauses

Viewport
SetForceDisableSplitscreen
static void Gameplay::SetForceDisableSplitscreen(	
bool 	bDisable
)
Enables split screen

Parameters
bDisable
bool
Whether the viewport should split screen between local players or not

IsSplitscreenForceDisabled
static bool Gameplay::IsSplitscreenForceDisabled()
Returns the split screen state

Returns
Whether the game viewport is split screen or not

GetViewportMouseCaptureMode
static EMouseCaptureMode Gameplay::GetViewportMouseCaptureMode()
Returns the current viewport mouse capture mode

SetViewportMouseCaptureMode
static void Gameplay::SetViewportMouseCaptureMode(	
EMouseCaptureMode 	MouseCaptureMode
)
Sets the current viewport mouse capture mode

Static Functions
AsyncSaveGameToSlot
static void Gameplay::AsyncSaveGameToSlot(
USaveGame 	SaveGameObject,		
FString 	SlotName,		
int 	UserIndex,		
FAsyncSaveGameToSlotDynamicDelegate 	Delegate	 = 	FAsyncSaveGameToSlotDynamicDelegate ( )
)
Schedule an async save to a specific slot. UAsyncActionHandleSaveGame::AsyncSaveGameToSlot is the blueprint version of this.  This will do the serialize on the game thread, the platform-specific write on a worker thread, then call the complete delegate on the game thread.  The passed in delegate will be copied to a worker thread so make sure any payload is thread safe to copy by value.

Parameters
SaveGameObject
USaveGame
Object that contains data about the save game that we want to write out.

SlotName
FString
Name of the save game slot to load from.

UserIndex
int
For some platforms, master user index to identify the user doing the loading.

AsyncLoadGameFromSlot
static void Gameplay::AsyncLoadGameFromSlot(
FString 	SlotName,		
int 	UserIndex,		
FAsyncLoadGameFromSlotDynamicDelegate 	Delegate	 = 	FAsyncLoadGameFromSlotDynamicDelegate ( )
)
Schedule an async load of a specific slot. UAsyncActionHandleSaveGame::AsyncLoadGameFromSlot is the blueprint version of this.  This will do the platform-specific read on a worker thread, the serialize and creation on the game thread, and then will call the passed in delegate The passed in delegate will be copied to a worker thread so make sure any payload is thread safe to copy by value

Parameters
SlotName
FString
Name of the save game slot to load from.

UserIndex
int
For some platforms, master user index to identify the user doing the loading.


System
System
Static Variables
LocalCurrencySymbol
static const FString System::LocalCurrencySymbol
BuildConfiguration
static const FString System::BuildConfiguration
BuildVersion
static const FString System::BuildVersion
CommandLine
static const FString System::CommandLine
DefaultLanguage
static const FString System::DefaultLanguage
DefaultLocale
static const FString System::DefaultLocale
DeviceId
static const FString System::DeviceId
EngineVersion
static const FString System::EngineVersion
FrameCount
static const int64 System::FrameCount
GameBundleId
static const FString System::GameBundleId
GameName
static const FString System::GameName
LocalCurrencyCode
static const FString System::LocalCurrencyCode
AdIDCount
static const int System::AdIDCount
MinYResolutionFor3DView
static const int System::MinYResolutionFor3DView
MinYResolutionForUI
static const int System::MinYResolutionForUI
PlatformUserDir
static const FString System::PlatformUserDir
PlatformUserName
static const FString System::PlatformUserName
PreferredLanguages
static const TArray<FString> System::PreferredLanguages
ProjectContentDirectory
static const FString System::ProjectContentDirectory
ProjectDirectory
static const FString System::ProjectDirectory
ProjectSavedDirectory
static const FString System::ProjectSavedDirectory
RenderingDetailMode
static const int System::RenderingDetailMode
RenderingMaterialQualityLevel
static const int System::RenderingMaterialQualityLevel
VolumeButtonsHandledBySystem
static bool System::VolumeButtonsHandledBySystem
Actor
GetActorListFromComponentList
static void System::GetActorListFromComponentList(	
TArray<UPrimitiveComponent> 	ComponentList,
UClass 	ActorClassFilter,
TArray<AActor>& 	OutActorList
)
Returns an array of unique actors represented by the given list of components.

Parameters
ComponentList
TArray<UPrimitiveComponent>
List of components.

OutActorList
TArray<AActor>&
Start of line segment.

AssetManager
GetPrimaryAssetIdFromSoftObjectReference
static FPrimaryAssetId System::GetPrimaryAssetIdFromSoftObjectReference(
TSoftObjectPtr<UObject> 	SoftObjectReference
)
Returns the Primary Asset Id for a Soft Object Reference, this can return an invalid one if not registered

GetPrimaryAssetIdList
static void System::GetPrimaryAssetIdList(	
FPrimaryAssetType 	PrimaryAssetType,
TArray<FPrimaryAssetId>& 	OutPrimaryAssetIdList
)
Returns list of PrimaryAssetIds for a PrimaryAssetType

GetPrimaryAssetsWithBundleState
static void System::GetPrimaryAssetsWithBundleState(
TArray<FName> 	RequiredBundles,
TArray<FName> 	ExcludedBundles,
TArray<FPrimaryAssetType> 	ValidTypes,
bool 	bForceCurrentState,
TArray<FPrimaryAssetId>& 	OutPrimaryAssetIdList
)
Returns the list of assets that are in a given bundle state. Required Bundles must be specified If ExcludedBundles is not empty, it will not return any assets in those bundle states If ValidTypes is not empty, it will only return assets of those types If ForceCurrentState is true it will use the current state even if a load is in process

UnloadPrimaryAssetList
static void System::UnloadPrimaryAssetList(	
TArray<FPrimaryAssetId> 	PrimaryAssetIdList
)
Unloads a primary asset, which allows it to be garbage collected if nothing else is referencing it

UnloadPrimaryAsset
static void System::UnloadPrimaryAsset(	
FPrimaryAssetId 	PrimaryAssetId
)
Unloads a primary asset, which allows it to be garbage collected if nothing else is referencing it

GetObjectFromPrimaryAssetId
static UObject System::GetObjectFromPrimaryAssetId(	
FPrimaryAssetId 	PrimaryAssetId
)
Returns the Object associated with a Primary Asset Id, this will only return a valid object if it is in memory, it will not load it

GetPrimaryAssetIdFromObject
static FPrimaryAssetId System::GetPrimaryAssetIdFromObject(	
UObject 	Object
)
Returns the Primary Asset Id for an Object, this can return an invalid one if not registered

IsValidPrimaryAssetType
static bool System::IsValidPrimaryAssetType(	
FPrimaryAssetType 	PrimaryAssetType
)
Returns list of Primary Asset Ids for a PrimaryAssetType

GetSoftObjectReferenceFromPrimaryAssetId
static TSoftObjectPtr<UObject> System::GetSoftObjectReferenceFromPrimaryAssetId(
FPrimaryAssetId 	PrimaryAssetId
)
Returns the Object Id associated with a Primary Asset Id, this works even if the asset is not loaded

GetSoftClassReferenceFromPrimaryAssetId
static TSoftClassPtr<UObject> System::GetSoftClassReferenceFromPrimaryAssetId(
FPrimaryAssetId 	PrimaryAssetId
)
Returns the Blueprint Class Id associated with a Primary Asset Id, this works even if the asset is not loaded

GetPrimaryAssetIdFromSoftClassReference
static FPrimaryAssetId System::GetPrimaryAssetIdFromSoftClassReference(
TSoftClassPtr<UObject> 	SoftClassReference
)
Returns the Primary Asset Id for a Soft Class Reference, this can return an invalid one if not registered

Conv_PrimaryAssetTypeToString
static FString System::Conv_PrimaryAssetTypeToString(	
FPrimaryAssetType 	PrimaryAssetType
)
Converts a Primary Asset Type to a string. The other direction is not provided because it cannot be validated

EqualEqual_PrimaryAssetType
static bool System::EqualEqual_PrimaryAssetType(	
FPrimaryAssetType 	A,
FPrimaryAssetType 	B
)
Returns true if the values are equal (A == B)

IsValidPrimaryAssetId
static bool System::IsValidPrimaryAssetId(	
FPrimaryAssetId 	PrimaryAssetId
)
Returns true if the Primary Asset Id is valid

NotEqual_PrimaryAssetId
static bool System::NotEqual_PrimaryAssetId(	
FPrimaryAssetId 	A,
FPrimaryAssetId 	B
)
Returns true if the values are not equal (A != B)

GetClassFromPrimaryAssetId
static TSubclassOf<UObject> System::GetClassFromPrimaryAssetId(	
FPrimaryAssetId 	PrimaryAssetId
)
Returns the Blueprint Class associated with a Primary Asset Id, this will only return a valid object if it is in memory, it will not load it

GetPrimaryAssetIdFromClass
static FPrimaryAssetId System::GetPrimaryAssetIdFromClass(	
TSubclassOf<UObject> 	Class
)
Returns the Primary Asset Id for a Class, this can return an invalid one if not registered

Conv_PrimaryAssetIdToString
static FString System::Conv_PrimaryAssetIdToString(	
FPrimaryAssetId 	PrimaryAssetId
)
Converts a Primary Asset Id to a string. The other direction is not provided because it cannot be validated

EqualEqual_PrimaryAssetId
static bool System::EqualEqual_PrimaryAssetId(	
FPrimaryAssetId 	A,
FPrimaryAssetId 	B
)
Returns true if the values are equal (A == B)

NotEqual_PrimaryAssetType
static bool System::NotEqual_PrimaryAssetType(	
FPrimaryAssetType 	A,
FPrimaryAssetType 	B
)
Returns true if the values are not equal (A != B)

GetCurrentBundleState
static bool System::GetCurrentBundleState(	
FPrimaryAssetId 	PrimaryAssetId,
bool 	bForceCurrentState,
TArray<FName>& 	OutBundles
)
Returns the list of loaded bundles for a given Primary Asset. This will return false if the asset is not loaded at all.  If ForceCurrentState is true it will return the current state even if a load is in process

Collision
CapsuleTraceSingleForObjects
static bool System::CapsuleTraceSingleForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a capsule along the given line and returns the first hit encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

SphereOverlapActors
static bool System::SphereOverlapActors(	
const 	FVector 	SpherePos,
float32 	SphereRadius,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ActorClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<AActor>& 	OutActors
)
Returns an array of actors that overlap the given sphere.

Parameters
SpherePos
const FVector
Center of sphere.

SphereRadius
float32
Size of sphere.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

OutActors
TArray<AActor>&
Returned array of actors. Unsorted.

Returns
true if there was an overlap that passed the filters, false otherwise.

BoxTraceSingle
static bool System::BoxTraceSingle(
const 	FVector 	Start,		
const 	FVector 	End,		
const 	FVector 	HalfSize,		
const 	FRotator 	Orientation,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a box along the given line and returns the first blocking hit encountered.  This trace finds the objects that RESPONDS to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
const FVector
Distance from the center of box along each axis

Orientation
const FRotator
Orientation of the box

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

SphereTraceMultiForObjects
static bool System::SphereTraceMultiForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a sphere along the given line and returns all hits encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a hit, false otherwise.

BoxTraceMultiForObjects
static bool System::BoxTraceMultiForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
const 	FVector 	HalfSize,		
const 	FRotator 	Orientation,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a box along the given line and returns all hits encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
const FVector
Radius of the sphere to sweep

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a hit, false otherwise.

CapsuleTraceSingleByProfile
static bool System::CapsuleTraceSingleByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a capsule against the world and return the first blocking hit using a specific profile

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

BoxTraceMulti
static bool System::BoxTraceMulti(
const 	FVector 	Start,		
const 	FVector 	End,		
FVector 	HalfSize,		
const 	FRotator 	Orientation,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a box along the given line and returns all hits encountered.  This trace finds the objects that RESPONDS to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
FVector
Distance from the center of box along each axis

Orientation
const FRotator
Orientation of the box

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish. The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

LineTraceMulti
static bool System::LineTraceMulti(
const 	FVector 	Start,		
const 	FVector 	End,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Does a collision trace along the given line and returns all hits encountered up to and including the first blocking hit.  This trace finds the objects that RESPOND to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

TraceChannel
ETraceTypeQuery
The channel to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

Returns
True if there was a blocking hit, false otherwise.

CapsuleTraceMultiForObjects
static bool System::CapsuleTraceMultiForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a capsule along the given line and returns all hits encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a hit, false otherwise.

LineTraceSingleForObjects
static bool System::LineTraceSingleForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Does a collision trace along the given line and returns the first hit encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

BoxTraceSingleForObjects
static bool System::BoxTraceSingleForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
const 	FVector 	HalfSize,		
const 	FRotator 	Orientation,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a box along the given line and returns the first hit encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
const FVector
Radius of the sphere to sweep

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

BoxTraceSingleByProfile
static bool System::BoxTraceSingleByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
const 	FVector 	HalfSize,		
const 	FRotator 	Orientation,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a box against the world and return the first blocking hit using a specific profile

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
const FVector
Distance from the center of box along each axis

Orientation
const FRotator
Orientation of the box

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

CapsuleTraceMultiByProfile
static bool System::CapsuleTraceMultiByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a capsule against the world and return all initial overlaps using a specific profile, then overlapping hits and then first blocking hit Results are sorted, so a blocking hit (if found) will be the last element of the array Only the single closest blocking result will be generated, no tests will be done after that

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

SphereTraceMultiByProfile
static bool System::SphereTraceMultiByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a sphere against the world and return all initial overlaps using a specific profile, then overlapping hits and then first blocking hit Results are sorted, so a blocking hit (if found) will be the last element of the array Only the single closest blocking result will be generated, no tests will be done after that

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

SphereOverlapComponents
static bool System::SphereOverlapComponents(
const 	FVector 	SpherePos,
float32 	SphereRadius,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ComponentClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<UPrimitiveComponent>& 	OutComponents
)
Returns an array of components that overlap the given sphere.

Parameters
SpherePos
const FVector
Center of sphere.

SphereRadius
float32
Size of sphere.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

Returns
true if there was an overlap that passed the filters, false otherwise.

CapsuleOverlapComponents
static bool System::CapsuleOverlapComponents(
const 	FVector 	CapsulePos,
float32 	Radius,
float32 	HalfHeight,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ComponentClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<UPrimitiveComponent>& 	OutComponents
)
Returns an array of components that overlap the given capsule.

Parameters
CapsulePos
const FVector
Center of the capsule.

Radius
float32
Radius of capsule hemispheres and radius of center cylinder portion.

HalfHeight
float32
Half-height of the capsule (from center of capsule to tip of hemisphere.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

Returns
true if there was an overlap that passed the filters, false otherwise.

LineTraceMultiByProfile
static bool System::LineTraceMultiByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Trace a ray against the world using a specific profile and return overlapping hits and then first blocking hit Results are sorted, so a blocking hit (if found) will be the last element of the array Only the single closest blocking result will be generated, no tests will be done after that

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

Returns
True if there was a blocking hit, false otherwise.

BoxOverlapActors
static bool System::BoxOverlapActors(	
const 	FVector 	BoxPos,
FVector 	BoxExtent,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ActorClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<AActor>& 	OutActors
)
Returns an array of actors that overlap the given axis-aligned box.

Parameters
BoxPos
const FVector
Center of box.

BoxExtent
FVector
Extents of box.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

OutActors
TArray<AActor>&
Returned array of actors. Unsorted.

Returns
true if there was an overlap that passed the filters, false otherwise.

SphereTraceSingleForObjects
static bool System::SphereTraceSingleForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a sphere along the given line and returns the first hit encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

SphereTraceSingle
static bool System::SphereTraceSingle(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a sphere along the given line and returns the first blocking hit encountered.  This trace finds the objects that RESPONDS to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

SphereTraceSingleByProfile
static bool System::SphereTraceSingleByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a sphere against the world and return the first blocking hit using a specific profile

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

CapsuleOverlapActors
static bool System::CapsuleOverlapActors(	
const 	FVector 	CapsulePos,
float32 	Radius,
float32 	HalfHeight,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ActorClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<AActor>& 	OutActors
)
Returns an array of actors that overlap the given capsule.

Parameters
CapsulePos
const FVector
Center of the capsule.

Radius
float32
Radius of capsule hemispheres and radius of center cylinder portion.

HalfHeight
float32
Half-height of the capsule (from center of capsule to tip of hemisphere.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

OutActors
TArray<AActor>&
Returned array of actors. Unsorted.

Returns
true if there was an overlap that passed the filters, false otherwise.

ComponentOverlapActors
static bool System::ComponentOverlapActors(	
UPrimitiveComponent 	Component,
FTransform 	ComponentTransform,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ActorClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<AActor>& 	OutActors
)
Returns an array of actors that overlap the given component.

Parameters
Component
UPrimitiveComponent
Component to test with.

ComponentTransform
FTransform
Defines where to place the component for overlap testing.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

OutActors
TArray<AActor>&
Returned array of actors. Unsorted.

Returns
true if there was an overlap that passed the filters, false otherwise.

BoxTraceMultiByProfile
static bool System::BoxTraceMultiByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
FVector 	HalfSize,		
const 	FRotator 	Orientation,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweep a box against the world and return all initial overlaps using a specific profile, then overlapping hits and then first blocking hit Results are sorted, so a blocking hit (if found) will be the last element of the array Only the single closest blocking result will be generated, no tests will be done after that

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

HalfSize
FVector
Distance from the center of box along each axis

Orientation
const FRotator
Orientation of the box

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish. The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

ComponentOverlapComponents
static bool System::ComponentOverlapComponents(	
UPrimitiveComponent 	Component,
FTransform 	ComponentTransform,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ComponentClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<UPrimitiveComponent>& 	OutComponents
)
Returns an array of components that overlap the given component.

Parameters
Component
UPrimitiveComponent
Component to test with.

ComponentTransform
FTransform
Defines where to place the component for overlap testing.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

Returns
true if there was an overlap that passed the filters, false otherwise.

LineTraceMultiForObjects
static bool System::LineTraceMultiForObjects(
const 	FVector 	Start,		
const 	FVector 	End,		
TArray<EObjectTypeQuery> 	ObjectTypes,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Does a collision trace along the given line and returns all hits encountered.  This only finds objects that are of a type specified by ObjectTypes.

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

ObjectTypes
TArray<EObjectTypeQuery>
Array of Object Types to trace

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

Returns
True if there was a hit, false otherwise.

GetComponentBounds
static void System::GetComponentBounds(	
const 	USceneComponent 	Component,
FVector& 	Origin,
FVector& 	BoxExtent,
float32& 	SphereRadius
)
Get bounds

CapsuleTraceSingle
static bool System::CapsuleTraceSingle(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a capsule along the given line and returns the first blocking hit encountered.  This trace finds the objects that RESPOND to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

CapsuleTraceMulti
static bool System::CapsuleTraceMulti(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
float32 	HalfHeight,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a capsule along the given line and returns all hits encountered up to and including the first blocking hit.  This trace finds the objects that RESPOND to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the capsule to sweep

HalfHeight
float32
Distance from center of capsule to tip of hemisphere endcap.

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

BoxOverlapComponents
static bool System::BoxOverlapComponents(	
const 	FVector 	BoxPos,
FVector 	Extent,
TArray<EObjectTypeQuery> 	ObjectTypes,
UClass 	ComponentClassFilter,
TArray<AActor> 	ActorsToIgnore,
TArray<UPrimitiveComponent>& 	OutComponents
)
Returns an array of components that overlap the given axis-aligned box.

Parameters
BoxPos
const FVector
Center of box.

ActorsToIgnore
TArray<AActor>
Ignore these actors in the list

Returns
true if there was an overlap that passed the filters, false otherwise.

LineTraceSingleByProfile
static bool System::LineTraceSingleByProfile(
const 	FVector 	Start,		
const 	FVector 	End,		
FName 	ProfileName,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Trace a ray against the world using a specific profile and return the first blocking hit

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

ProfileName
FName
The 'profile' used to determine which components to hit

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

LineTraceSingle
static bool System::LineTraceSingle(
const 	FVector 	Start,		
const 	FVector 	End,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
FHitResult& 	OutHit,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Does a collision trace along the given line and returns the first blocking hit encountered.  This trace finds the objects that RESPONDS to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHit
FHitResult&
Properties of the trace hit.

Returns
True if there was a hit, false otherwise.

SphereTraceMulti
static bool System::SphereTraceMulti(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius,		
ETraceTypeQuery 	TraceChannel,		
bool 	bTraceComplex,		
TArray<AActor> 	ActorsToIgnore,		
EDrawDebugTrace 	DrawDebugType,		
TArray<FHitResult>& 	OutHits,		
bool 	bIgnoreSelf,		
FLinearColor 	TraceColor	 = 	FLinearColor ( 1.000000 , 0.000000 , 0.000000 , 1.000000 ),
FLinearColor 	TraceHitColor	 = 	FLinearColor ( 0.000000 , 1.000000 , 0.000000 , 1.000000 ),
float32 	DrawTime	 = 	5.000000
)
Sweeps a sphere along the given line and returns all hits encountered up to and including the first blocking hit.  This trace finds the objects that RESPOND to the given TraceChannel

Parameters
Start
const FVector
Start of line segment.

End
const FVector
End of line segment.

Radius
float32
Radius of the sphere to sweep

bTraceComplex
bool
True to test against complex collision, false to test against simplified collision.

OutHits
TArray<FHitResult>&
A list of hits, sorted along the trace from start to finish.  The blocking hit will be the last hit, if there was one.

Returns
True if there was a blocking hit, false otherwise.

Components
MoveComponentTo
static void System::MoveComponentTo(	
USceneComponent 	Component,
FVector 	TargetRelativeLocation,
FRotator 	TargetRelativeRotation,
bool 	bEaseOut,
bool 	bEaseIn,
float32 	OverTime,
bool 	bForceShortestRotationPath,
EMoveComponentAction 	MoveAction,
FLatentActionInfo 	LatentInfo
)
Interpolate a component to the specified relative location and rotation over the course of OverTime seconds.  *

Parameters
Component
USceneComponent
Component to interpolate *

TargetRelativeLocation
FVector
Relative target location *

TargetRelativeRotation
FRotator
Relative target rotation *

bEaseOut
bool
if true we will ease out (ie end slowly) during interpolation *

bEaseIn
bool
if true we will ease in (ie start slowly) during interpolation *

OverTime
float32
duration of interpolation *

bForceShortestRotationPath
bool
if true we will always use the shortest path for rotation *

MoveAction
EMoveComponentAction
required movement behavior

LatentInfo
FLatentActionInfo
The latent action

Development
SetUserActivity
static void System::SetUserActivity(	
FUserActivity 	UserActivity
)
Tells the engine what the user is doing for debug, analytics, etc.

ExecuteConsoleCommand
static void System::ExecuteConsoleCommand(	
FString 	Command,		
APlayerController 	SpecificPlayer	 = 	nullptr
)
Executes a console command, optionally on a specific controller

Parameters
Command
FString
Command to send to the console

SpecificPlayer
APlayerController
If specified, the console command will be routed through the specified player

GetBuildConfiguration
static FString System::GetBuildConfiguration()
Build configuration, for displaying to end users in diagnostics.

GetBuildVersion
static FString System::GetBuildVersion()
Build version, for displaying to end users in diagnostics.

GetConsoleVariableBoolValue
static bool System::GetConsoleVariableBoolValue(	
FString 	VariableName
)
Evaluates, if it exists, whether the specified integer console variable has a non-zero value (true) or not (false).

Parameters
VariableName
FString
Name of the console variable to find.

Returns
True if found and has a non-zero value, false otherwise.

GetConsoleVariableFloatValue
static float32 System::GetConsoleVariableFloatValue(	
FString 	VariableName
)
Attempts to retrieve the value of the specified float console variable, if it exists.

Parameters
VariableName
FString
Name of the console variable to find.

Returns
The value if found, 0 otherwise.

GetConsoleVariableIntValue
static int System::GetConsoleVariableIntValue(	
FString 	VariableName
)
Attempts to retrieve the value of the specified integer console variable, if it exists.

Parameters
VariableName
FString
Name of the console variable to find.

Returns
The value if found, 0 otherwise.

GetEngineVersion
static FString System::GetEngineVersion()
Engine build number, for displaying to end users.

PrintString
static void System::PrintString(
FString 	InString	 = 	"",
bool 	bPrintToScreen	 = 	true,
bool 	bPrintToLog	 = 	true,
FLinearColor 	TextColor	 = 	FLinearColor ( 0.000000 , 0.660000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	2.000000,
const 	FName 	Key	 = 	NAME_None
)
Prints a string to the log, and optionally, to the screen If Print To Log is true, it will be visible in the Output Log window.  Otherwise it will be logged only as 'Verbose', so it generally won't show up.

Parameters
InString
FString
The string to log out

bPrintToScreen
bool
Whether or not to print the output to the screen

bPrintToLog
bool
Whether or not to print the output to the log

TextColor
FLinearColor
The color of the text to display

Duration
float32
The display duration (if Print to Screen is True). Using negative number will result in loading the duration time from the config.

Key
const FName
If a non-empty key is provided, the message will replace any existing on-screen messages with the same key.

PrintText
static void System::PrintText(
const 	FText 	InText,		
bool 	bPrintToScreen	 = 	true,
bool 	bPrintToLog	 = 	true,
FLinearColor 	TextColor	 = 	FLinearColor ( 0.000000 , 0.660000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	2.000000,
const 	FName 	Key	 = 	NAME_None
)
Prints text to the log, and optionally, to the screen If Print To Log is true, it will be visible in the Output Log window.  Otherwise it will be logged only as 'Verbose', so it generally won't show up.

Parameters
InText
const FText
The text to log out

bPrintToScreen
bool
Whether or not to print the output to the screen

bPrintToLog
bool
Whether or not to print the output to the log

TextColor
FLinearColor
The color of the text to display

Duration
float32
The display duration (if Print to Screen is True). Using negative number will result in loading the duration time from the config.

Key
const FName
If a non-empty key is provided, the message will replace any existing on-screen messages with the same key.

QuitEditor
static void System::QuitEditor()
Exit the editor

IsPackagedForDistribution
static bool System::IsPackagedForDistribution()
Returns whether this is a build that is packaged for distribution

Development|Editor
CreateCopyForUndoBuffer
static void System::CreateCopyForUndoBuffer(	
UObject 	ObjectToModify
)
Mark as modified.

Game
GetGameBundleId
static FString System::GetGameBundleId()
Retrieves the game's platform-specific bundle identifier or package name of the game

Returns
The game's bundle identifier or package name.

GetGameName
static FString System::GetGameName()
Get the name of the current game

QuitGame
static void System::QuitGame(	
APlayerController 	SpecificPlayer,
EQuitPreference 	QuitPreference,
bool 	bIgnorePlatformRestrictions
)
Exit the current game

Parameters
SpecificPlayer
APlayerController
The specific player to quit the game. If not specified, player 0 will quit.

QuitPreference
EQuitPreference
Form of quitting.

bIgnorePlatformRestrictions
bool
Ignores and best-practices based on platform (e.g on some consoles, games should never quit). Non-shipping only

Math|Boolean
MakeLiteralBool
static bool System::MakeLiteralBool(	
bool 	Value
)
Creates a literal bool

Parameters
Value
bool
value to set the bool to

Returns
The literal bool

Math|Byte
MakeLiteralByte
static uint8 System::MakeLiteralByte(	
uint8 	Value
)
Creates a literal byte

Parameters
Value
uint8
value to set the byte to

Returns
The literal byte

Math|Double
MakeLiteralDouble
static float System::MakeLiteralDouble(	
float 	Value
)
Creates a literal double

Parameters
Value
float
value to set the double to

Returns
The literal double

Math|Float
MakeLiteralFloat
static float32 System::MakeLiteralFloat(	
float32 	Value
)
Creates a literal float

Parameters
Value
float32
value to set the float to

Returns
The literal float

Math|Integer
MakeLiteralInt
static int System::MakeLiteralInt(	
int 	Value
)
Creates a literal integer

Parameters
Value
int
value to set the integer to

Returns
The literal integer

MakeLiteralInt64
static int64 System::MakeLiteralInt64(	
int64 	Value
)
Creates a literal 64-bit integer

Parameters
Value
int64
value to set the 64-bit integer to

Returns
The literal 64-bit integer

Networking
IsStandalone
static bool System::IsStandalone()
Returns whether this game instance is stand alone (no networking).

IsServer
static bool System::IsServer()
Returns whether the world this object is in is the host or not

IsDedicatedServer
static bool System::IsDedicatedServer()
Returns whether this is running on a dedicated server

Online
IsLoggedIn
static bool System::IsLoggedIn(	
const 	APlayerController 	SpecificPlayer
)
Returns whether the player is logged in to the currently active online subsystem.

Rendering
GetConvenientWindowedResolutions
static bool System::GetConvenientWindowedResolutions(	
TArray<FIntPoint>& 	Resolutions
)
Gets the list of windowed resolutions which are convenient for the current primary display size.

Returns
true if successfully queried the device for available resolutions.

GetMinYResolutionForUI
static int System::GetMinYResolutionForUI()
Gets the smallest Y resolution we want to support in the UI, clamped within reasons

Returns
value in pixels

GetMinYResolutionFor3DView
static int System::GetMinYResolutionFor3DView()
Gets the smallest Y resolution we want to support in the 3D view, clamped within reasons

Returns
value in pixels

GetRenderingDetailMode
static int System::GetRenderingDetailMode()
Get the clamped state of r.DetailMode, see console variable help (allows for scalability, cannot be used in construction scripts) 0: low, show only object with DetailMode low or higher 1: medium, show all object with DetailMode medium or higher 2: high, show all objects

GetSupportedFullscreenResolutions
static bool System::GetSupportedFullscreenResolutions(	
TArray<FIntPoint>& 	Resolutions
)
Gets the list of support fullscreen resolutions.

Returns
true if successfully queried the device for available resolutions.

Rendering|Debug
FlushDebugStrings
static void System::FlushDebugStrings()
Removes all debug strings.

FlushPersistentDebugLines
static void System::FlushPersistentDebugLines()
Flush all persistent debug lines and shapes.

DrawDebugArrow
static void System::DrawDebugArrow(	
const 	FVector 	LineStart,		
const 	FVector 	LineEnd,		
float32 	ArrowSize,		
FLinearColor 	LineColor,		
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw directional arrow, pointing from LineStart to LineEnd.

DrawDebugBox
static void System::DrawDebugBox(	
const 	FVector 	Center,		
FVector 	Extent,		
FLinearColor 	LineColor,		
const 	FRotator 	Rotation	 = 	FRotator ( ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug box

DrawDebugCamera
static void System::DrawDebugCamera(
const 	ACameraActor 	CameraActor,		
FLinearColor 	CameraColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000
)
Draw a debug camera shape.

DrawDebugCapsule
static void System::DrawDebugCapsule(
const 	FVector 	Center,		
float32 	HalfHeight,		
float32 	Radius,		
const 	FRotator 	Rotation,		
FLinearColor 	LineColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug capsule

DrawDebugCircle
static void System::DrawDebugCircle(
FVector 	Center,		
float32 	Radius,		
int 	NumSegments	 = 	12,
FLinearColor 	LineColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000,
FVector 	YAxis	 = 	FVector ( 0.000000 , 1.000000 , 0.000000 ),
FVector 	ZAxis	 = 	FVector ( 0.000000 , 0.000000 , 1.000000 ),
bool 	bDrawAxis	 = 	false
)
Draw a debug circle!

DrawDebugConeInDegrees
static void System::DrawDebugConeInDegrees(
const 	FVector 	Origin,		
const 	FVector 	Direction,		
float32 	Length	 = 	100.000000,
float32 	AngleWidth	 = 	45.000000,
float32 	AngleHeight	 = 	45.000000,
int 	NumSides	 = 	12,
FLinearColor 	LineColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug cone Angles are specified in degrees

DrawDebugCoordinateSystem
static void System::DrawDebugCoordinateSystem(	
const 	FVector 	AxisLoc,		
const 	FRotator 	AxisRot,		
float32 	Scale	 = 	1.000000,
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug coordinate system.

AddFloatHistorySample
static FDebugFloatHistory System::AddFloatHistorySample(	
float32 	Value,
FDebugFloatHistory 	FloatHistory
)
DrawDebugCylinder
static void System::DrawDebugCylinder(
const 	FVector 	Start,		
const 	FVector 	End,		
float32 	Radius	 = 	100.000000,
int 	Segments	 = 	12,
FLinearColor 	LineColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug cylinder

DrawDebugFloatHistoryLocation
static void System::DrawDebugFloatHistoryLocation(
FDebugFloatHistory 	FloatHistory,		
FVector 	DrawLocation,		
FVector2D 	DrawSize,		
FLinearColor 	DrawColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000
)
Draws a 2D Histogram of size 'DrawSize' based FDebugFloatHistory struct, using DrawLocation for the location in the world, rotation will face camera of first player.

DrawDebugFloatHistoryTransform
static void System::DrawDebugFloatHistoryTransform(
FDebugFloatHistory 	FloatHistory,		
FTransform 	DrawTransform,		
FVector2D 	DrawSize,		
FLinearColor 	DrawColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000
)
Draws a 2D Histogram of size 'DrawSize' based FDebugFloatHistory struct, using DrawTransform for the position in the world.

DrawDebugFrustum
static void System::DrawDebugFrustum(
FTransform 	FrustumTransform,		
FLinearColor 	FrustumColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draws a debug frustum.

DrawDebugLine
static void System::DrawDebugLine(	
const 	FVector 	LineStart,		
const 	FVector 	LineEnd,		
FLinearColor 	LineColor,		
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug line

DrawDebugPlane
static void System::DrawDebugPlane(
FPlane 	PlaneCoordinates,		
const 	FVector 	Location,		
float32 	Size,		
FLinearColor 	PlaneColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000
)
Draws a debug plane.

DrawDebugPoint
static void System::DrawDebugPoint(	
const 	FVector 	Position,		
float32 	Size,		
FLinearColor 	PointColor,		
float32 	Duration	 = 	0.000000
)
Draw a debug point

DrawDebugSphere
static void System::DrawDebugSphere(
const 	FVector 	Center,		
float32 	Radius	 = 	100.000000,
int 	Segments	 = 	12,
FLinearColor 	LineColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000,
float32 	Thickness	 = 	0.000000
)
Draw a debug sphere

DrawDebugString
static void System::DrawDebugString(
const 	FVector 	TextLocation,		
FString 	Text,		
AActor 	TestBaseActor	 = 	nullptr,
FLinearColor 	TextColor	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
float32 	Duration	 = 	0.000000
)
Draw a debug string at a 3d world location.

Rendering|Material
GetRenderingMaterialQualityLevel
static int System::GetRenderingMaterialQualityLevel()
Get the clamped state of r.MaterialQualityLevel, see console variable help (allows for scalability, cannot be used in construction scripts) 0: low 1: high 2: medium

Transactions
CancelTransaction
static void System::CancelTransaction(	
int 	Index
)
Cancel the current transaction, and no longer capture actions to be placed in the undo buffer.  Note: Only available in the editor.

Parameters
Index
int
The action counter to cancel transactions from (as returned by a call to BeginTransaction).

TransactObject
static void System::TransactObject(	
UObject 	Object
)
Notify the current transaction (if any) that this object is about to be modified and should be placed into the undo buffer.  Note: Internally this calls Modify on the given object, so will also mark the owner package dirty.  Note: Only available in the editor.

Parameters
Object
UObject
The object that is about to be modified.

SnapshotObject
static void System::SnapshotObject(	
UObject 	Object
)
Notify the current transaction (if any) that this object is about to be modified and should be snapshot for intermediate update.  Note: Internally this calls SnapshotTransactionBuffer on the given object.  Note: Only available in the editor.

Parameters
Object
UObject
The object that is about to be modified.

EndTransaction
static int System::EndTransaction()
Attempt to end the current undo transaction. Only successful if the transaction's action counter is 1.  Note: Only available in the editor.

Returns
The number of active actions when EndTransaction was called (a value of 1 indicates that the transaction was successfully closed), or -1 on failure.

BeginTransaction
static int System::BeginTransaction(	
FString 	Context,
FText 	Description,
UObject 	PrimaryObject
)
Begin a new undo transaction. An undo transaction is defined as all actions which take place when the user selects "undo" a single time.  Note: If there is already an active transaction in progress, then this increments that transaction's action counter instead of beginning a new transaction.  Note: You must call TransactObject before modifying each object that should be included in this undo transaction.  Note: Only available in the editor.

Parameters
Context
FString
The context for the undo session. Typically the tool/editor that caused the undo operation.

Description
FText
The description for the undo session. This is the text that will appear in the "Edit" menu next to the Undo item.

PrimaryObject
UObject
The primary object that the undo session operators on (can be null, and mostly is).

Returns
The number of active actions when BeginTransaction was called (values greater than 0 indicate that there was already an existing undo transaction in progress), or -1 on failure.

Utilities
EqualEqual_SoftClassReference
static bool System::EqualEqual_SoftClassReference(	
TSoftClassPtr<UObject> 	A,
TSoftClassPtr<UObject> 	B
)
Returns true if the values are equal (A == B)

EqualEqual_SoftObjectReference
static bool System::EqualEqual_SoftObjectReference(	
TSoftObjectPtr<UObject> 	A,
TSoftObjectPtr<UObject> 	B
)
Returns true if the values are equal (A == B)

Conv_ObjectToClass
static UClass System::Conv_ObjectToClass(	
UObject 	Object,
TSubclassOf<UObject> 	Class
)
Converts an object into a class

BreakSoftClassPath
static void System::BreakSoftClassPath(	
FSoftClassPath 	InSoftClassPath,
FString& 	PathString
)
Gets the path string out of a Soft Class Path

Conv_SoftClassPathToSoftClassRef
static TSoftClassPtr<UObject> System::Conv_SoftClassPathToSoftClassRef(
FSoftClassPath 	SoftClassPath
)
Converts a Soft Class Path into a base Soft Class Reference, this is not guaranteed to be resolvable

BreakSoftObjectPath
static void System::BreakSoftObjectPath(	
FSoftObjectPath 	InSoftObjectPath,
FString& 	PathString
)
Gets the path string out of a Soft Object Path

Conv_SoftClassReferenceToString
static FString System::Conv_SoftClassReferenceToString(	
TSoftClassPtr<UObject> 	SoftClassReference
)
Converts a Soft Class Reference to a string. The other direction is not provided because it cannot be validated

GetClassDisplayName
static FString System::GetClassDisplayName(	
UClass 	Class
)
Returns the display name of a class

Conv_SoftObjectReferenceToString
static FString System::Conv_SoftObjectReferenceToString(
TSoftObjectPtr<UObject> 	SoftObjectReference
)
Converts a Soft Object Reference to a string. The other direction is not provided because it cannot be validated

GetCommandLine
static FString System::GetCommandLine()
Returns the command line that the process was launched with.

Conv_SoftObjPathToSoftObjRef
static TSoftObjectPtr<UObject> System::Conv_SoftObjPathToSoftObjRef(	
FSoftObjectPath 	SoftObjectPath
)
Converts a Soft Object Path into a base Soft Object Reference, this is not guaranteed to be resolvable

GetFrameCount
static int64 System::GetFrameCount()
Returns the value of GFrameCounter, a running count of the number of frames that have occurred.

DoesImplementInterface
static bool System::DoesImplementInterface(	
const 	UObject 	TestObject,
TSubclassOf<UInterface> 	Interface
)
Checks if this object implements a specific interface, works for both native and blueprint interfacse

GetObjectName
static FString System::GetObjectName(	
const 	UObject 	Object
)
Returns the actual object name.

GetOuterObject
static UObject System::GetOuterObject(	
const 	UObject 	Object
)
Returns the outer object of an object.

GetPathName
static FString System::GetPathName(	
const 	UObject 	Object
)
Returns the full path to the specified object.

GetDisplayName
static FString System::GetDisplayName(	
const 	UObject 	Object
)
Returns the display name (or actor label), for displaying as a debugging aid.  Note: In editor builds, this is the actor label.  In non-editor builds, this is the actual object name.  This function should not be used to uniquely identify actors!  It is not localized and should not be used for display to an end user of a game.

IsValid
static bool System::IsValid(	
const 	UObject 	Object
)
Return true if the object is usable : non-null and not pending kill

IsValidClass
static bool System::IsValidClass(	
UClass 	Class
)
Return true if the class is usable : non-null and not pending kill

NotEqual_SoftClassReference
static bool System::NotEqual_SoftClassReference(	
TSoftClassPtr<UObject> 	A,
TSoftClassPtr<UObject> 	B
)
Returns true if the values are not equal (A != B)

NotEqual_SoftObjectReference
static bool System::NotEqual_SoftObjectReference(	
TSoftObjectPtr<UObject> 	A,
TSoftObjectPtr<UObject> 	B
)
Returns true if the values are not equal (A != B)

ParseCommandLine
static void System::ParseCommandLine(	
FString 	InCmdLine,
TArray<FString>& 	OutTokens,
TArray<FString>& 	OutSwitches,
TMap<FString,FString>& 	OutParams
)
* Parses the given string into loose tokens, switches (arguments that begin with	
or /) and parameters (-mySwitch=myVar) * *

Parameters
InCmdLine
FString
The the string to parse (ie '-foo -bar=/game/baz testtoken' ) *

IsValidSoftClassReference
static bool System::IsValidSoftClassReference(	
TSoftClassPtr<UObject> 	SoftClassReference
)
Returns true if the Soft Class Reference is not null

MakeSoftClassPath
static FSoftClassPath System::MakeSoftClassPath(	
FString 	PathString
)
Builds a SoftClassPath struct. Generally you should be using Soft Class References/Ptr types instead

LoadAsset_Blocking
static UObject System::LoadAsset_Blocking(	
TSoftObjectPtr<UObject> 	Asset
)
Resolves or loads a Soft Object Reference immediately, this will cause hitches and Async Load Asset should be used if possible

IsUnattended
static bool System::IsUnattended()
Returns true if running unattended (-unattended is on the command line)

Returns
Unattended state

LoadClassAsset_Blocking
static UClass System::LoadClassAsset_Blocking(	
TSoftClassPtr<UObject> 	AssetClass
)
Resolves or loads a Soft Class Reference immediately, this will cause hitches and Async Load Class Asset should be used if possible

IsValidSoftObjectReference
static bool System::IsValidSoftObjectReference(	
TSoftObjectPtr<UObject> 	SoftObjectReference
)
Returns true if the Soft Object Reference is not null

ParseParamValue
static bool System::ParseParamValue(	
FString 	InString,
FString 	InParam,
FString& 	OutValue
)
Returns 'value' if -option=value is in the string

MakeSoftObjectPath
static FSoftObjectPath System::MakeSoftObjectPath(	
FString 	PathString
)
Builds a SoftObjectPath struct. Generally you should be using Soft Object References/Ptr types instead

ParseParam
static bool System::ParseParam(	
FString 	InString,
FString 	InParam
)
Returns true if the string has -param in it (do not specify the leading -)

Utilities|FlowControl
RetriggerableDelay
static void System::RetriggerableDelay(	
float32 	Duration,
FLatentActionInfo 	LatentInfo
)
Perform a latent action with a retriggerable delay (specified in seconds).  Calling again while it is counting down will reset the countdown to Duration.

Parameters
Duration
float32
length of delay (in seconds).

LatentInfo
FLatentActionInfo
The latent action.

DelayUntilNextTick
static void System::DelayUntilNextTick(	
FLatentActionInfo 	LatentInfo
)
Perform a latent action with a delay of one tick.  Calling again while it is counting down will be ignored.

Parameters
LatentInfo
FLatentActionInfo
The latent action.

Delay
static void System::Delay(	
float32 	Duration,
FLatentActionInfo 	LatentInfo
)
Perform a latent action with a delay (specified in seconds).  Calling again while it is counting down will be ignored.

Parameters
Duration
float32
length of delay (in seconds).

LatentInfo
FLatentActionInfo
The latent action.

Utilities|Internationalization
GetPreferredLanguages
static TArray<FString> System::GetPreferredLanguages()
Returns an array of the user's preferred languages in order of preference

Returns
An array of language IDs ordered from most preferred to least

GetDefaultLanguage
static FString System::GetDefaultLanguage()
Get the default language (for localization) used by this platform Note: This is typically the same as GetDefaultLocale unless the platform distinguishes between the two Note: This should be returned in IETF language tag form: - A two-letter ISO 639-1 language code (eg, "zh") - An optional four-letter ISO 15924 script code (eg, "Hans") - An optional two-letter ISO 3166-1 country code (eg, "CN")

Returns
The language as an IETF language tag (eg, "zh-Hans-CN")

GetDefaultLocale
static FString System::GetDefaultLocale()
Get the default locale (for internationalization) used by this platform Note: This should be returned in IETF language tag form: - A two-letter ISO 639-1 language code (eg, "zh") - An optional four-letter ISO 15924 script code (eg, "Hans") - An optional two-letter ISO 3166-1 country code (eg, "CN")

Returns
The locale as an IETF language tag (eg, "zh-Hans-CN")

GetLocalCurrencySymbol
static FString System::GetLocalCurrencySymbol()
Returns the currency symbol associated with the device's locale

Returns
the currency symbol associated with the device's locale

GetLocalCurrencyCode
static FString System::GetLocalCurrencyCode()
Returns the currency code associated with the device's locale

Returns
the currency code associated with the device's locale

Utilities|Name
MakeLiteralName
static FName System::MakeLiteralName(	
FName 	Value
)
Creates a literal name

Parameters
Value
FName
value to set the name to

Returns
The literal name

Utilities|Paths
GetProjectSavedDirectory
static FString System::GetProjectSavedDirectory()
Get the saved directory of the current project

ConvertToRelativePath
static FString System::ConvertToRelativePath(	
FString 	Filename
)
Converts passed in filename to use a relative path

ConvertToAbsolutePath
static FString System::ConvertToAbsolutePath(	
FString 	Filename
)
Converts passed in filename to use a absolute path

GetProjectDirectory
static FString System::GetProjectDirectory()
Get the directory of the current project

GetProjectContentDirectory
static FString System::GetProjectContentDirectory()
Get the content directory of the current project

NormalizeFilename
static FString System::NormalizeFilename(	
FString 	InFilename
)
Convert all / and \ to TEXT("/")

GetSystemPath
static FString System::GetSystemPath(	
const 	UObject 	Object
)
Returns the full system path to a UObject If given a non-asset UObject, it will return an empty string

Utilities|Platform
GetPlatformUserName
static FString System::GetPlatformUserName()
Get the current user name from the OS

LaunchURL
static void System::LaunchURL(	
FString 	URL
)
Opens the specified URL in the platform's web browser of choice

GetPlatformUserDir
static FString System::GetPlatformUserDir()
Get the current user dir from the OS

HideAdBanner
static void System::HideAdBanner()
Hides the ad banner (iAd on iOS, or AdMob on Android). Will force close the ad if it's open (iOS and Android only)

GetAdIDCount
static int System::GetAdIDCount()
Retrieves the total number of Ad IDs that can be selected between

ForceCloseAdBanner
static void System::ForceCloseAdBanner()
Forces closed any displayed ad. Can lead to loss of revenue (iOS and Android only)

ControlScreensaver
static void System::ControlScreensaver(	
bool 	bAllowScreenSaver
)
Allows or inhibits screensaver

Parameters
bAllowScreenSaver
bool
If false, don't allow screensaver if possible, otherwise allow default behavior

CollectGarbage
static void System::CollectGarbage()
Deletes all unreferenced objects, keeping only referenced objects (this command will be queued and happen at the end of the frame) Note: This can be a slow operation, and should only be performed where a hitch would be acceptable

LoadInterstitialAd
static void System::LoadInterstitialAd(	
int 	AdIdIndex
)
Will load a fullscreen interstitial AdMob ad. Call this before using ShowInterstitialAd (Android only)

Parameters
AdIdIndex
int
The index of the ID to select for the ad to show

GetVolumeButtonsHandledBySystem
static bool System::GetVolumeButtonsHandledBySystem()
Returns true if system default handling of volume up and volume down buttons enabled (Android only)

IsInterstitialAdAvailable
static bool System::IsInterstitialAdAvailable()
Returns true if the requested interstitial ad is loaded and ready (Android only)

CanLaunchURL
static bool System::CanLaunchURL(	
FString 	URL
)
GetGamepadControllerName
static FString System::GetGamepadControllerName(	
int 	ControllerId
)
Returns name of controller if assigned to a gamepad (or None if not assigned) (Android and iOS only)

IsScreensaverEnabled
static bool System::IsScreensaverEnabled()
Returns true if screen saver is enabled.

GetGamepadButtonGlyph
static UTexture2D System::GetGamepadButtonGlyph(	
FString 	ButtonKey,
int 	ControllerIndex
)
Returns glyph assigned to a gamepad button (or a null ptr if not assigned) (iOS and tvOS only)

GetDeviceId
static FString System::GetDeviceId()
Returns the platform specific unique device id

IsInterstitialAdRequested
static bool System::IsInterstitialAdRequested()
Returns true if the requested interstitial ad has been successfully requested (false if load request fails) (Android only)

IsControllerAssignedToGamepad
static bool System::IsControllerAssignedToGamepad(	
int 	ControllerId
)
Returns true if controller id assigned to a gamepad (Android and iOS only)

UnregisterForRemoteNotifications
static void System::UnregisterForRemoteNotifications()
Requests Requests unregistering from receiving remote notifications to the user's device.  (Android only)

RegisterForRemoteNotifications
static void System::RegisterForRemoteNotifications()
Requests permission to send remote notifications to the user's device.  (Android and iOS only)

SetGamepadsBlockDeviceFeedback
static void System::SetGamepadsBlockDeviceFeedback(	
bool 	bBlock
)
Sets whether attached gamepads will block feedback from the device itself (Mobile only).

SetVolumeButtonsHandledBySystem
static void System::SetVolumeButtonsHandledBySystem(	
bool 	bEnabled
)
Allows or inhibits system default handling of volume up and volume down buttons (Android only)

Parameters
bEnabled
bool
If true, allow Android to handle volume up and down events

ShowPlatformSpecificLeaderboardScreen
static void System::ShowPlatformSpecificLeaderboardScreen(	
FString 	CategoryName
)
Displays the built-in leaderboard GUI (iOS and Android only; this function may be renamed or moved in a future release)

ShowAdBanner
static void System::ShowAdBanner(	
int 	AdIdIndex,
bool 	bShowOnBottomOfScreen
)
Will show an ad banner (iAd on iOS, or AdMob on Android) on the top or bottom of screen, on top of the GL view (doesn't resize the view) (iOS and Android only)

Parameters
AdIdIndex
int
The index of the ID to select for the ad to show

bShowOnBottomOfScreen
bool
If true, the iAd will be shown at the bottom of the screen, top otherwise

ShowInterstitialAd
static void System::ShowInterstitialAd()
Shows the loaded interstitial ad (loaded with LoadInterstitialAd) (Android only)

ShowPlatformSpecificAchievementsScreen
static void System::ShowPlatformSpecificAchievementsScreen(	
const 	APlayerController 	SpecificPlayer
)
Displays the built-in achievements GUI (iOS and Android only; this function may be renamed or moved in a future release)

Parameters
SpecificPlayer
const APlayerController
Specific player's achievements to show. May not be supported on all platforms. If null, defaults to the player with ControllerId 0

ResetGamepadAssignments
static void System::ResetGamepadAssignments()
Resets the gamepad to player controller id assignments (Android and iOS only)

ResetGamepadAssignmentToController
static void System::ResetGamepadAssignmentToController(	
int 	ControllerId
)
Resets the gamepad assignment to player controller id (Android and iOS only)

SetWindowTitle
static void System::SetWindowTitle(	
FText 	Title
)
Sets the game window title

Utilities|String
LogString
static void System::LogString(	
FString 	InString	 = 	"",
bool 	bPrintToLog	 = 	true
)
Prints a string to the log If Print To Log is true, it will be visible in the Output Log window.  Otherwise it will be logged only as 'Verbose', so it generally won't show up.

Parameters
InString
FString
The string to log out

bPrintToLog
bool
Whether or not to print the output to the log

MakeLiteralString
static FString System::MakeLiteralString(	
FString 	Value
)
Creates a literal string

Parameters
Value
FString
value to set the string to

Returns
The literal string

Utilities|Text
MakeLiteralText
static FText System::MakeLiteralText(	
FText 	Value
)
Creates a literal FText

Parameters
Value
FText
value to set the FText to

Returns
The literal FText

Utilities|Time
IsTimerActiveHandle
static bool System::IsTimerActiveHandle(	
FTimerHandle 	Handle
)
Returns true if a timer exists and is active for the given handle, false otherwise.

Parameters
Handle
FTimerHandle
The handle of the timer to check whether it is active.

Returns
True if the timer exists and is active.

IsTimerActive
static bool System::IsTimerActive(	
UObject 	Object,
FString 	FunctionName
)
Returns true if a timer exists and is active for the given delegate, false otherwise.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
True if the timer exists and is active.

SetTimerForNextTick
static FTimerHandle System::SetTimerForNextTick(	
UObject 	Object,
FString 	FunctionName
)
Set a timer to execute a delegate on the next tick.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
The timer handle to pass to other timer functions to manipulate this timer.

GetTimerRemainingTime
static float32 System::GetTimerRemainingTime(	
UObject 	Object,
FString 	FunctionName
)
Returns time until the timer will next execute its delegate.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
How long is remaining in the current iteration of the timer.

TimerExists
static bool System::TimerExists(	
UObject 	Object,
FString 	FunctionName
)
Returns true is a timer for the given delegate exists, false otherwise.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
True if the timer exists.

GetGameTimeInSeconds
static float32 System::GetGameTimeInSeconds()
Get the current game time, in seconds. This stops when the game is paused and is affected by slomo.

Parameters
WorldContextObject	
World context

GetTimerRemainingTimeHandle
static float32 System::GetTimerRemainingTimeHandle(	
FTimerHandle 	Handle
)
Returns time until the timer will next execute its handle.

Parameters
Handle
FTimerHandle
The handle of the timer to time remaining of.

Returns
How long is remaining in the current iteration of the timer.

GetTimerElapsedTime
static float32 System::GetTimerElapsedTime(	
UObject 	Object,
FString 	FunctionName
)
Returns elapsed time for the given delegate (time since current countdown iteration began).

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
How long has elapsed since the current iteration of the timer began.

UnPauseTimerHandle
static void System::UnPauseTimerHandle(	
FTimerHandle 	Handle
)
Resumes a paused timer from its current elapsed time.

Parameters
Handle
FTimerHandle
The handle of the timer to unpause.

PauseTimerHandle
static void System::PauseTimerHandle(	
FTimerHandle 	Handle
)
Pauses a set timer at its current elapsed time.

Parameters
Handle
FTimerHandle
The handle of the timer to pause.

SetTimerForNextTickDelegate
static FTimerHandle System::SetTimerForNextTickDelegate(
FTimerDynamicDelegate 	Delegate	 = 	FTimerDynamicDelegate ( )
)
Set a timer to execute a delegate next tick.

Returns
The timer handle to pass to other timer functions to manipulate this timer.

UnPauseTimer
static void System::UnPauseTimer(	
UObject 	Object,
FString 	FunctionName
)
Resumes a paused timer from its current elapsed time.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

GetTimerElapsedTimeHandle
static float32 System::GetTimerElapsedTimeHandle(	
FTimerHandle 	Handle
)
Returns elapsed time for the given handle (time since current countdown iteration began).

Parameters
Handle
FTimerHandle
The handle of the timer to get the elapsed time of.

Returns
How long has elapsed since the current iteration of the timer began.

InvalidateTimerHandle
static FTimerHandle System::InvalidateTimerHandle(	
FTimerHandle& 	Handle
)
Invalidate the supplied TimerHandle and return it.

Parameters
Handle
FTimerHandle&
The handle of the timer to invalidate.

Returns
Return the invalidated timer handle for convenience.

PauseTimer
static void System::PauseTimer(	
UObject 	Object,
FString 	FunctionName
)
Pauses a set timer at its current elapsed time.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

ClearTimer
static void System::ClearTimer(	
UObject 	Object,
FString 	FunctionName
)
Clears a set timer.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

IsValidTimerHandle
static bool System::IsValidTimerHandle(	
FTimerHandle 	Handle
)
Returns whether the timer handle is valid. This does not indicate that there is an active timer that this handle references, but rather that it once referenced a valid timer.

Parameters
Handle
FTimerHandle
The handle of the timer to check validity of.

Returns
Whether the timer handle is valid.

IsTimerPausedHandle
static bool System::IsTimerPausedHandle(	
FTimerHandle 	Handle
)
Returns true if a timer exists and is paused for the given handle, false otherwise.

Parameters
Handle
FTimerHandle
The handle of the timer to check whether it is paused.

Returns
True if the timer exists and is paused.

ClearAndInvalidateTimerHandle
static void System::ClearAndInvalidateTimerHandle(	
FTimerHandle& 	Handle
)
Clears a set timer.

Parameters
Handle
FTimerHandle&
The handle of the timer to clear.

IsTimerPaused
static bool System::IsTimerPaused(	
UObject 	Object,
FString 	FunctionName
)
Returns true if a timer exists and is paused for the given delegate, false otherwise.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FString
Delegate function name. Can be a K2 function or a Custom Event.

Returns
True if the timer exists and is paused.

TimerExistsHandle
static bool System::TimerExistsHandle(	
FTimerHandle 	Handle
)
Returns true is a timer for the given handle exists, false otherwise.

Parameters
Handle
FTimerHandle
The handle to check whether it exists.

Returns
True if the timer exists.

SetTimerDelegate
static FTimerHandle System::SetTimerDelegate(
FTimerDynamicDelegate 	Delegate,		
float32 	Time,		
bool 	bLooping,		
float32 	InitialStartDelay	 = 	0.000000,
float32 	InitialStartDelayVariance	 = 	0.000000
)
Set a timer to execute delegate. Setting an existing timer will reset that timer with updated parameters.

Parameters
Time
float32
How long to wait before executing the delegate, in seconds. Setting a timer to <= 0 seconds will clear it if it is set.

bLooping
bool
True to keep executing the delegate every Time seconds, false to execute delegate only once.

InitialStartDelay
float32
Initial delay passed to the timer manager, in seconds.

InitialStartDelayVariance
float32
Use this to add some variance to when the timer starts in lieu of doing a random range on the InitialStartDelay input, in seconds.

Returns
The timer handle to pass to other timer functions to manipulate this timer.

SetTimer
static FTimerHandle System::SetTimer(	
UObject 	Object,		
FName 	FunctionName,		
float32 	Time,		
bool 	bLooping,		
float32 	InitialStartDelay	 = 	0.000000,
float32 	InitialStartDelayVariance	 = 	0.000000
)
Set a timer to execute delegate. Setting an existing timer will reset that timer with updated parameters.

Parameters
Object
UObject
Object that implements the delegate function. Defaults to self (this blueprint)

FunctionName
FName
Delegate function name. Can be a K2 function or a Custom Event.

Time
float32
How long to wait before executing the delegate, in seconds. Setting a timer to <= 0 seconds will clear it if it is set.

bLooping
bool
true to keep executing the delegate every Time seconds, false to execute delegate only once.

InitialStartDelay
float32
Initial delay passed to the timer manager to allow some variance in when the timer starts, in seconds.

InitialStartDelayVariance
float32
Use this to add some variance to when the timer starts in lieu of doing a random range on the InitialStartDelay input, in seconds.

Returns
The timer handle to pass to other timer functions to manipulate this timer.

Viewport
HasMultipleLocalPlayers
static bool System::HasMultipleLocalPlayers()
Returns whether there are currently multiple local players in the given world

SetSuppressViewportTransitionMessage
static void System::SetSuppressViewportTransitionMessage(	
bool 	bState
)
Sets the state of the transition message rendered by the viewport. (The blue text displayed when the game is paused and so forth.)

Parameters
WorldContextObject	
World context

Static Functions
AsyncOverlapByChannel
static FTraceHandle System::AsyncOverlapByChannel(
FVector 	Pos,		
FQuat 	Rot,		
ECollisionChannel 	TraceChannel,		
FCollisionShape 	CollisionShape,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FCollisionResponseParams 	ResponseParam	 = 	FCollisionResponseParams :: DefaultResponseParam,
FScriptOverlapDelegate 	InDelegate	 = 	FScriptOverlapDelegate ( ),
uint 	UserData	 = 	0
)
AsyncSweepByProfile
static FTraceHandle System::AsyncSweepByProfile(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
FQuat 	Rot,		
FName 	ProfileName,		
FCollisionShape 	CollisionShape,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)
AsyncLineTraceByChannel
static FTraceHandle System::AsyncLineTraceByChannel(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
ECollisionChannel 	TraceChannel,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FCollisionResponseParams 	ResponseParam	 = 	FCollisionResponseParams :: DefaultResponseParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)
AsyncLineTraceByObjectType
static FTraceHandle System::AsyncLineTraceByObjectType(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
FCollisionObjectQueryParams 	ObjectQueryParams,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)
IsTraceHandleValid
static bool System::IsTraceHandleValid(	
FTraceHandle 	Handle,
bool 	bOverlapTrace
)
QueryOverlapData
static bool System::QueryOverlapData(	
FTraceHandle 	Handle,
FOverlapDatum& 	OutData
)
QueryTraceData
static bool System::QueryTraceData(	
FTraceHandle 	Handle,
FTraceDatum& 	OutData
)
AsyncOverlapByObjectType
static FTraceHandle System::AsyncOverlapByObjectType(
FVector 	Pos,		
FQuat 	Rot,		
FCollisionObjectQueryParams 	ObjectQueryParams,		
FCollisionShape 	CollisionShape,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FScriptOverlapDelegate 	InDelegate	 = 	FScriptOverlapDelegate ( ),
uint 	UserData	 = 	0
)
AsyncLineTraceByProfile
static FTraceHandle System::AsyncLineTraceByProfile(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
FName 	ProfileName,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)
AsyncSweepByObjectType
static FTraceHandle System::AsyncSweepByObjectType(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
FQuat 	Rot,		
FCollisionObjectQueryParams 	ObjectQueryParams,		
FCollisionShape 	CollisionShape,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)
AsyncSweepByChannel
static FTraceHandle System::AsyncSweepByChannel(
EAsyncTraceType 	InTraceType,		
FVector 	Start,		
FVector 	End,		
FQuat 	Rot,		
ECollisionChannel 	TraceChannel,		
FCollisionShape 	CollisionShape,		
FCollisionQueryParams 	Params	 = 	FCollisionQueryParams :: DefaultQueryParam,
FCollisionResponseParams 	ResponseParam	 = 	FCollisionResponseParams :: DefaultResponseParam,
FScriptTraceDelegate 	InDelegate	 = 	FScriptTraceDelegate ( ),
uint 	UserData	 = 	0
)

Niagara
Niagara
Niagara
SetSkeletalMeshDataInterfaceSamplingRegions
static void Niagara::SetSkeletalMeshDataInterfaceSamplingRegions(	
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
TArray<FName> 	SamplingRegions
)
Sets the SamplingRegion to use on the skeletal mesh data interface, this is destructive as it modifies the data interface.

GetNiagaraParameterCollection
static UNiagaraParameterCollectionInstance Niagara::GetNiagaraParameterCollection(
UNiagaraParameterCollection 	Collection
)
This is gonna be totally reworked UFUNCTION(BlueprintCallable, Category = Niagara, meta = (Keywords = "niagara System", UnsafeDuringActorConstruction = "true")) static void SetUpdateScriptConstant(UNiagaraComponent* Component, FName EmitterName, FName ConstantName, FVector Value);

OverrideSystemUserVariableSkeletalMeshComponent
static void Niagara::OverrideSystemUserVariableSkeletalMeshComponent(
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
USkeletalMeshComponent 	SkeletalMeshComponent
)
Sets a Niagara StaticMesh parameter by name, overriding locally if necessary.

OverrideSystemUserVariableStaticMesh
static void Niagara::OverrideSystemUserVariableStaticMesh(	
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
UStaticMesh 	StaticMesh
)
OverrideSystemUserVariableStaticMeshComponent
static void Niagara::OverrideSystemUserVariableStaticMeshComponent(
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
UStaticMeshComponent 	StaticMeshComponent
)
Sets a Niagara StaticMesh parameter by name, overriding locally if necessary.

ReleaseNiagaraGPURayTracedCollisionGroup
static void Niagara::ReleaseNiagaraGPURayTracedCollisionGroup(	
int 	CollisionGroup
)
Releases a collision group back to the system for use by ohers.

SetActorNiagaraGPURayTracedCollisionGroup
static void Niagara::SetActorNiagaraGPURayTracedCollisionGroup(	
AActor 	Actor,
int 	CollisionGroup
)
Sets the Niagara GPU ray traced collision group for all primitive components on the given actor.

SetComponentNiagaraGPURayTracedCollisionGroup
static void Niagara::SetComponentNiagaraGPURayTracedCollisionGroup(
UPrimitiveComponent 	Primitive,
int 	CollisionGroup
)
Sets the Niagara GPU ray traced collision group for the give primitive component.

AcquireNiagaraGPURayTracedCollisionGroup
static int Niagara::AcquireNiagaraGPURayTracedCollisionGroup()
Returns a free collision group for use in HWRT collision group filtering. Returns -1 on failure.

SetTexture2DArrayObject
static void Niagara::SetTexture2DArrayObject(	
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
UTexture2DArray 	Texture
)
Overrides the 2D Array Texture for a Niagara 2D Array Texture Data Interface User Parameter.

SetTextureObject
static void Niagara::SetTextureObject(	
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
UTexture 	Texture
)
Overrides the Texture Object for a Niagara Texture Data Interface User Parameter.

SetVolumeTextureObject
static void Niagara::SetVolumeTextureObject(	
UNiagaraComponent 	NiagaraSystem,
FString 	OverrideName,
UVolumeTexture 	Texture
)
Overrides the Volume Texture for a Niagara Volume Texture Data Interface User Parameter.

SpawnSystemAtLocation
static UNiagaraComponent Niagara::SpawnSystemAtLocation(
UNiagaraSystem 	SystemTemplate,		
FVector 	Location,		
FRotator 	Rotation	 = 	FRotator ( ),
FVector 	Scale	 = 	FVector ( 1.000000 , 1.000000 , 1.000000 ),
bool 	bAutoDestroy	 = 	true,
bool 	bAutoActivate	 = 	true,
ENCPoolMethod 	PoolingMethod	 = 	ENCPoolMethod :: None,
bool 	bPreCullCheck	 = 	true
)
Spawns a Niagara System at the specified world location/rotation

Returns
The spawned UNiagaraComponent

SpawnSystemAtLocationWithParams
static UNiagaraComponent Niagara::SpawnSystemAtLocationWithParams(
FFXSystemSpawnParameters& 	SpawnParams
)
SpawnSystemAttached
static UNiagaraComponent Niagara::SpawnSystemAttached(
UNiagaraSystem 	SystemTemplate,		
USceneComponent 	AttachToComponent,		
FName 	AttachPointName,		
FVector 	Location,		
FRotator 	Rotation,		
EAttachLocation 	LocationType,		
bool 	bAutoDestroy,		
bool 	bAutoActivate	 = 	true,
ENCPoolMethod 	PoolingMethod	 = 	ENCPoolMethod :: None,
bool 	bPreCullCheck	 = 	true
)
SpawnSystemAttachedWithParams
static UNiagaraComponent Niagara::SpawnSystemAttachedWithParams(
FFXSystemSpawnParameters& 	SpawnParams
)

Widget
Widget
Static Variables
DragDroppingContent
static const UDragDropOperation Widget::DragDroppingContent
Focus
SetFocusToGameViewport
static void Widget::SetFocusToGameViewport()
Input
SetInputMode_GameOnly
static void Widget::SetInputMode_GameOnly(	
APlayerController 	PlayerController
)
Setup an input mode that allows only player input / player controller to respond to user input.

Note: Any bound Input Events in this widget will be called.

SetInputMode_GameAndUIEx
static void Widget::SetInputMode_GameAndUIEx(
APlayerController 	PlayerController,		
UWidget 	InWidgetToFocus	 = 	nullptr,
EMouseLockMode 	InMouseLockMode	 = 	EMouseLockMode :: DoNotLock,
bool 	bHideCursorDuringCapture	 = 	true
)
Setup an input mode that allows only the UI to respond to user input, and if the UI doesn't handle it player input / player controller gets a chance.

Note: This means that any bound Input events in the widget will be called.

SetInputMode_UIOnlyEx
static void Widget::SetInputMode_UIOnlyEx(
APlayerController 	PlayerController,		
UWidget 	InWidgetToFocus	 = 	nullptr,
EMouseLockMode 	InMouseLockMode	 = 	EMouseLockMode :: DoNotLock
)
Setup an input mode that allows only the UI to respond to user input.

Note: This means that any bound Input Events in the widget will not be called!

Painting
DrawTextFormatted
static void Widget::DrawTextFormatted(
FPaintContext& 	Context,		
FText 	Text,		
FVector2D 	Position,		
UFont 	Font,		
int 	FontSize	 = 	16,
FName 	FontTypeFace	 = 	FName ( "" ),
FLinearColor 	Tint	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 )
)
Draws text.

Parameters
Text
FText
The string to draw.

Position
FVector2D
The starting position where the text is drawn in local space.

Tint
FLinearColor
Color to render the line.

DrawBox
static void Widget::DrawBox(
FPaintContext& 	Context,		
FVector2D 	Position,		
FVector2D 	Size,		
USlateBrushAsset 	Brush,		
FLinearColor 	Tint	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 )
)
Draws a box

DrawLine
static void Widget::DrawLine(
FPaintContext& 	Context,		
FVector2D 	PositionA,		
FVector2D 	PositionB,		
FLinearColor 	Tint	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
bool 	bAntiAlias	 = 	true,
float32 	Thickness	 = 	1.000000
)
Draws a line.

Parameters
PositionA
FVector2D
Starting position of the line in local space.

PositionB
FVector2D
Ending position of the line in local space.

Tint
FLinearColor
Color to render the line.

bAntiAlias
bool
Whether the line should be antialiased.

Thickness
float32
How many pixels thick this line should be.

DrawLines
static void Widget::DrawLines(
FPaintContext& 	Context,		
TArray<FVector2D> 	Points,		
FLinearColor 	Tint	 = 	FLinearColor ( 1.000000 , 1.000000 , 1.000000 , 1.000000 ),
bool 	bAntiAlias	 = 	true,
float32 	Thickness	 = 	1.000000
)
Draws several line segments.

Parameters
Points
TArray<FVector2D>
Line pairs, each line needs to be 2 separate points in the array.

Tint
FLinearColor
Color to render the line.

bAntiAlias
bool
Whether the line should be antialiased.

Thickness
float32
How many pixels thick this line should be.

Widget
GetInputEventFromCharacterEvent
static FInputEvent Widget::GetInputEventFromCharacterEvent(	
FCharacterEvent 	Event
)
GetKeyEventFromAnalogInputEvent
static FKeyEvent Widget::GetKeyEventFromAnalogInputEvent(	
FAnalogInputEvent 	Event
)
GetInputEventFromNavigationEvent
static FInputEvent Widget::GetInputEventFromNavigationEvent(	
FNavigationEvent 	Event
)
GetAllWidgetsOfClass
static void Widget::GetAllWidgetsOfClass(	
TArray<UUserWidget>& 	FoundWidgets,		
TSubclassOf<UUserWidget> 	WidgetClass,		
bool 	TopLevelOnly	 = 	true
)
Find all widgets of a certain class.

Parameters
FoundWidgets
TArray<UUserWidget>&
The widgets that were found matching the filter.

WidgetClass
TSubclassOf<UUserWidget>
The widget class to filter by.

TopLevelOnly
bool
Only the widgets that are direct children of the viewport will be returned.

GetAllWidgetsWithInterface
static void Widget::GetAllWidgetsWithInterface(	
TArray<UUserWidget>& 	FoundWidgets,
TSubclassOf<UInterface> 	Interface,
bool 	TopLevelOnly
)
Find all widgets in the world with the specified interface.  This is a slow operation, use with caution e.g. do not use every frame.

Parameters
FoundWidgets
TArray<UUserWidget>&
Output array of widgets that implement the specified interface.

Interface
TSubclassOf<UInterface>
The interface to find. Must be specified or result array will be empty.

TopLevelOnly
bool
Only the widgets that are direct children of the viewport will be returned.

GetInputEventFromPointerEvent
static FInputEvent Widget::GetInputEventFromPointerEvent(	
FPointerEvent 	Event
)
GetInputEventFromKeyEvent
static FInputEvent Widget::GetInputEventFromKeyEvent(	
FKeyEvent 	Event
)
Widget|Accessibility
SetColorVisionDeficiencyType
static void Widget::SetColorVisionDeficiencyType(
EColorVisionDeficiency 	Type,
float32 	Severity,
bool 	CorrectDeficiency,
bool 	ShowCorrectionWithDeficiency
)
Apply color deficiency correction settings to the game window

Parameters
Type
EColorVisionDeficiency
The type of color deficiency correction to apply.

Severity
float32
Intensity of the color deficiency correction effect, from 0 to 1.

CorrectDeficiency
bool
Shifts the color spectrum to the visible range based on the current deficiency type.

ShowCorrectionWithDeficiency
bool
If you're correcting the color deficiency, you can use this to visualize what the correction looks like with the deficiency.

Widget|Brush
MakeBrushFromAsset
static FSlateBrush Widget::MakeBrushFromAsset(	
USlateBrushAsset 	BrushAsset
)
Creates a Slate Brush from a Slate Brush Asset

Returns
A new slate brush using the asset's brush.

MakeBrushFromTexture
static FSlateBrush Widget::MakeBrushFromTexture(	
UTexture2D 	Texture,		
int 	Width	 = 	0,
int 	Height	 = 	0
)
Creates a Slate Brush from a Texture2D

Parameters
Width
int
When less than or equal to zero, the Width of the brush will default to the Width of the Texture

Height
int
When less than or equal to zero, the Height of the brush will default to the Height of the Texture

Returns
A new slate brush using the texture.

MakeBrushFromMaterial
static FSlateBrush Widget::MakeBrushFromMaterial(	
UMaterialInterface 	Material,		
int 	Width	 = 	32,
int 	Height	 = 	32
)
Creates a Slate Brush from a Material.  Materials don't have an implicit size, so providing a widget and height is required to hint slate with how large the image wants to be by default.

Returns
A new slate brush using the material.

NoResourceBrush
static FSlateBrush Widget::NoResourceBrush()
Creates a Slate Brush that wont draw anything, the "Null Brush".

Returns
A new slate brush that wont draw anything.

GetBrushResourceAsMaterial
static UMaterialInterface Widget::GetBrushResourceAsMaterial(	
FSlateBrush 	Brush
)
Gets the brush resource as a material.

GetBrushResource
static UObject Widget::GetBrushResource(	
FSlateBrush 	Brush
)
Gets the resource object on a brush.  This could be a UTexture2D or a UMaterialInterface.

GetBrushResourceAsTexture2D
static UTexture2D Widget::GetBrushResourceAsTexture2D(	
FSlateBrush 	Brush
)
Gets the brush resource as a texture 2D.

GetDynamicMaterial
static UMaterialInstanceDynamic Widget::GetDynamicMaterial(	
FSlateBrush& 	Brush
)
Gets the material that allows changes to parameters at runtime.  The brush must already have a material assigned to it, if it does it will automatically be converted to a MID.

Returns
A material that supports dynamic input from the game.

SetBrushResourceToMaterial
static void Widget::SetBrushResourceToMaterial(	
FSlateBrush& 	Brush,
UMaterialInterface 	Material
)
Sets the resource on a brush to be a Material.

SetBrushResourceToTexture
static void Widget::SetBrushResourceToTexture(	
FSlateBrush& 	Brush,
UTexture2D 	Texture
)
Sets the resource on a brush to be a UTexture2D.

Widget|Drag and Drop
CancelDragDrop
static void Widget::CancelDragDrop()
Cancels any current drag drop operation.

IsDragDropping
static bool Widget::IsDragDropping()
Returns true if a drag/drop event is occurring that a widget can handle.

GetDragDroppingContent
static UDragDropOperation Widget::GetDragDroppingContent()
Returns the drag and drop operation that is currently occurring if any, otherwise nothing.

Widget|Drag and Drop|Event Reply
EndDragDrop
static FEventReply Widget::EndDragDrop(	
FEventReply& 	Reply
)
An event should return FReply::Handled().EndDragDrop() to request that the current drag/drop operation be terminated.

DetectDrag
static FEventReply Widget::DetectDrag(	
FEventReply& 	Reply,
UWidget 	WidgetDetectingDrag,
FKey 	DragKey
)
Ask Slate to detect if a user starts dragging in this widget later.  Slate internally tracks the movement and if it surpasses the drag threshold, Slate will send an OnDragDetected event to the widget.

Parameters
WidgetDetectingDrag
UWidget
Detect dragging in this widget

DragKey
FKey
This button should be pressed to detect the drag

DetectDragIfPressed
static FEventReply Widget::DetectDragIfPressed(	
FPointerEvent 	PointerEvent,
UWidget 	WidgetDetectingDrag,
FKey 	DragKey
)
Given the pointer event, emit the DetectDrag reply if the provided key was pressed.  If the DragKey is a touch key, that will also automatically work.

Parameters
PointerEvent
FPointerEvent
The pointer device event coming in.

WidgetDetectingDrag
UWidget
Detect dragging in this widget.

DragKey
FKey
This button should be pressed to detect the drag, won't emit the DetectDrag FEventReply unless this is pressed.

Widget|Event Reply
ReleaseMouseCapture
static FEventReply Widget::ReleaseMouseCapture(	
FEventReply& 	Reply
)
LockMouse
static FEventReply Widget::LockMouse(	
FEventReply& 	Reply,
UWidget 	CapturingWidget
)
CaptureMouse
static FEventReply Widget::CaptureMouse(	
FEventReply& 	Reply,
UWidget 	CapturingWidget
)
ClearUserFocus
static FEventReply Widget::ClearUserFocus(	
FEventReply& 	Reply,		
bool 	bInAllUsers	 = 	false
)
Handled
static FEventReply Widget::Handled()
The event reply to use when you choose to handle an event.  This will prevent the event from continuing to bubble up / down the widget hierarchy.

SetUserFocus
static FEventReply Widget::SetUserFocus(	
FEventReply& 	Reply,		
UWidget 	FocusWidget,		
bool 	bInAllUsers	 = 	false
)
Unhandled
static FEventReply Widget::Unhandled()
The event reply to use when you choose not to handle an event.

UnlockMouse
static FEventReply Widget::UnlockMouse(	
FEventReply& 	Reply
)
SetMousePosition
static FEventReply Widget::SetMousePosition(	
FEventReply& 	Reply,
FVector2D 	NewMousePosition
)
Widget|Hardware Cursor
SetHardwareCursor
static bool Widget::SetHardwareCursor(	
EMouseCursor 	CursorShape,
FName 	CursorName,
FVector2D 	HotSpot
)
Loads or sets a hardware cursor from the content directory in the game.

Widget|Menu
DismissAllMenus
static void Widget::DismissAllMenus()
Closes any popup menu

Widget|Safe Zone
GetSafeZonePadding
static void Widget::GetSafeZonePadding(	
FVector4& 	SafePadding,
FVector2D& 	SafePaddingScale,
FVector4& 	SpillOverPadding
)
Gets the amount of padding that needs to be added when accounting for the safe zone on TVs.

Widget|Window Title Bar
SetWindowTitleBarState
static void Widget::SetWindowTitleBarState(	
UWidget 	TitleBarContent,
EWindowTitleBarMode 	Mode,
bool 	bTitleBarDragEnabled,
bool 	bWindowButtonsVisible,
bool 	bTitleBarVisible
)
SetWindowTitleBarOnCloseClickedDelegate
static void Widget::SetWindowTitleBarOnCloseClickedDelegate(
FOnGameWindowCloseButtonClickedDelegate__WidgetBlueprintLibrary 	Delegate	 = 	FOnGameWindowCloseButtonClickedDelegate__WidgetBlueprintLibrary ( )
)
RestorePreviousWindowTitleBarState
static void Widget::RestorePreviousWindowTitleBarState()
SetWindowTitleBarCloseButtonActive
static void Widget::SetWindowTitleBarCloseButtonActive(	
bool 	bActive
)



