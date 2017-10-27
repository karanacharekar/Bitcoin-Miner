defmodule Project1 do 
  use GenServer

  def main(args) do
    args |> parse_args 
  end

  def parse_args([]) do
      IO.puts "No arguments given" 
  end    

  # THIS FUNCTION PARSES ARGUMENTS AND DECIDES BETWEEN SERVER AND CLIENT 

  def parse_args(args) do
      {_, [input], _} = OptionParser.parse(args)
      input_val = to_string input
      if(String.contains?(input_val,".") == true) do
          client_start(input_val)
      else
          server_start(elem(Integer.parse(input_val),0)) 
      end
   end

  # THIS FUNCTION STARTS THE SERVER   

  def server_start(k) do
    server_name = "server@" <> get_ip_addr()
    IO.puts server_name <> " has started"
    Node.start(String.to_atom(server_name))
    Node.set_cookie :"choco"
    string_set = MapSet.new
    GenServer.start_link(__MODULE__, {k,string_set}, name: :miner)
    call_from_server(server_name,k)
    IO.gets ""
  end  

  def util() do
    list = iterate_list([],0)
    util
  end

# THIS FUNCTION STARTS THE CLIENT

  def client_start(server_ip) do
    client_name =  "client@" <> get_ip_addr()
    Node.start(String.to_atom(client_name))
    IO.puts client_name <> " has started"
    Node.set_cookie :"choco"
    server_name = "server@" <> server_ip
    IO.puts server_name
    Node.connect(String.to_atom(server_name)) 
    
    for x <- 0..8 do
             pid = spawn fn -> Project1.bitcoin_miner_client(server_name) end  
             spawn_link fn -> Project1.util() end
    end 
    Project1.bitcoin_miner_client(server_name)
  end

  def bitcoin_miner_client(server_name) do
    {:news, liststring ,messages}  = GenServer.call({:miner,String.to_atom(server_name)},{:get_work,"karan"},:infinity)
    {size,_} =  messages

    str = "karanacharekar;" <> Project1.string_generator
    {:hash,ret,hashed} = process_sha_256(str,size)  
    if(ret != "") do
      IO.puts "hello"
    GenServer.cast({:miner,String.to_atom(server_name)},{:print_bitcoins_hashvalue,{:hash,ret,hashed}})
    end

    Enum.each liststring, fn x ->
    str2 = "karanacharekar;" <>  x
    {:hash,ret,hashed} = process_sha_256(str2,size)  
    if(ret != "") do
      IO.puts "hi"
    GenServer.cast({:miner,String.to_atom(server_name)},{:print_bitcoins_hashvalue,{:hash,ret,hashed}})
    end
    end
    bitcoin_miner_client(server_name)
    end


  def bitcoin_miner(server_name,size) do
    str = "karanacharekar;" <> Project1.string_generator
    {:hash,ret,hashed} = process_sha_256(str,size)  
    if(ret != "") do
      GenServer.cast({:miner,String.to_atom(server_name)},{:print_bitcoins_hashvalue,{:hash,ret,hashed}})
    end
    bitcoin_miner(server_name,size)
  end

  # HASHING FUNCTION

  def process_sha_256(str,l) do
    hashed = :crypto.hash(:sha256,str) |> Base.encode16
    substr = String.slice hashed, 0..l-1
    substr_chck = String.duplicate("0",l)
    if substr == substr_chck do      
      {:hash,str,hashed}
    else
      {:hash,"",""}
    end
  end

  # GENERATE RANDOM STRING

  def string_generator do
    x = Enum.to_list(0..9)
    y = for n <- ?a..?z, do: << n :: utf8 >>
    z = x ++ y
    w = for n <- ?A..?Z, do: << n :: utf8 >>
    u = z ++ w
    cg = Enum.join(Enum.shuffle(u))
    len = Enum.random(Enum.concat([15..30]))
    cg_sub = String.slice cg, 0..len 
    cg_sub
   end 

  # GET IP ADDRESS

  def get_ip_addr do 
    {:ok,lst} = :inet.getif()
    z = elem(List.last(lst),0) 
    if elem(z,0)==127 do
    x = elem(List.first(lst),0)
    addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
    else
    x = elem(List.last(lst),0)
    addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
    end
    addr  
  end

  def call_from_server(server_name,size) do
    IO.puts "server started "    
    for x <- 0..8 do
          spawn fn -> Project1.bitcoin_miner(server_name,size) end 
    end  
  end

  # SERVER FUNCTIONS
    def init(count) do
    {:ok, count}
    end
     
    def get_bitcoin_zeros(message) do
      GenServer.call(:miner, {:get_bitcoin_zeros, message})
    end


    def get_work(message) do
      GenServer.call(:miner, {:get_work, message})
    end

    def print_bitcoins_hashvalue(message) do
      GenServer.cast(:miner, {:print_bitcoins_hashvalue, message})
    end


  def handle_cast({:print_bitcoins_hashvalue ,new_message},messages) do
      {:hash,a,b} = new_message
      IO.puts "#{a}  #{b}"
      {:noreply, messages}
    end
      
  def iterate_list(list,num) do
      if num < 1000 do
      cg_sub = Project1.string_generator
      list = list ++ [cg_sub]
      iterate_list(list,num+1)
      else
      list
      end
      end

  def handle_call({:get_work ,new_message}, _from,messages) do
      list = Project1.iterate_list([],0) 
      {:reply, {:news, list ,messages}, messages}   
    end

end
