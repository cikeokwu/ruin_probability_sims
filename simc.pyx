from cython.view cimport array
import numpy as np
cimport numpy as np


DTYPE = np.float
ctypedef np.float_t DTYPE_t


# Simulations keeping aggregate attributes fixed
cpdef float simulate_effect(double p, double avg_income, double avg_shock_time, double max_shock_size, int num_agents=2, int diff=0, int seed=-1):
    cdef int i
    cdef int j
    if seed > -1 :
        seed = np.random.uniform(0, seed)
        np.random.seed(seed)
    #Per Simulation Variables
    incomes_preview = array(shape=(num_agents,), itemsize=sizeof(double), format="d")
    cdef double[:] incomes = incomes_preview
    shock_times_param_preview = array(shape=(num_agents,), itemsize=sizeof(double), format="d")
    cdef double[:] shock_times_param = shock_times_param_preview
    shock_size_param_preview = array(shape=(num_agents,), itemsize=sizeof(double), format="d")
    cdef double[:] shock_size_param = shock_size_param_preview
    if diff == 0:
        incomes[:] = avg_income
        shock_times_param[:] = avg_shock_time
        shock_size_param[:] = max_shock_size
    elif diff == 1:
        #creating incomes with fixed average income
        incomes[0] = 0.75 * num_agents * avg_income
        incomes[1] = 0.25 * num_agents * avg_income
        shock_times_param[:] = avg_shock_time
        shock_size_param[:] = max_shock_size
    elif diff == 2:
        incomes[:] = avg_income
        #creating shock_times with fixed average shock times
        shock_times_param[0] = 0.75 * num_agents * avg_shock_time
        shock_times_param[1] = 0.25 * num_agents * avg_shock_time
        shock_size_param[:] = max_shock_size
    elif diff == 3:
        incomes[:] = avg_income
        shock_times_param[:] = avg_shock_time
        #creating shock_sizes with fixed average shock size
        shock_size_param[0] = 0.75 * num_agents * max_shock_size
        shock_size_param[1] = 0.25 * num_agents * max_shock_size



    cdef bint savings_ruined = False
    cdef double savings_reserve = 0
    #initialize agent reserves to 0
    agent_reserves_preview = array(shape=(num_agents,), itemsize=sizeof(double), format="d")
    cdef double[:] agent_reserves = agent_reserves_preview
    agent_reserves[:] = 0
    #get all the agent shock times
    cdef int max_time = 1000
    agent_shock_times_preview = array(shape=(num_agents, max_time), itemsize=sizeof(int), format="i")
    cdef int[:, :] agent_shock_times = agent_shock_times_preview
    for i in range(num_agents):
        for j in range(max_time):
            agent_shock_times[i, j] = np.random.poisson(shock_times_param[i])
    cdef int time_step = 0
    cdef int agent
    cdef double shock_size
    cdef double savings_shock
    while not savings_ruined and time_step < max_time:
        for i in range(num_agents):
            agent_reserves[i] += (1 - p) * incomes[i]
        for i in range(num_agents):
            savings_reserve += p * incomes[i]
        # Simulating for each agent
        for agent in range(num_agents):
            #print(f"{agent_shock_times[agent][time_step]} shocks happening in this time period for agent {agent} ")
            for i in range(agent_shock_times[agent][time_step]):  # number of shocks in a given time interval
                if savings_ruined:
                    break
                shock_size = np.random.uniform(0, shock_size_param[agent])  # getting shock sizes per shock. Shock size at most twice income
                #print(f" shock {i} of size {shock_size} happenings with reserve {agent_reserves[agent]}")
                if agent_reserves[agent] - shock_size > 0:
                    agent_reserves[agent] -= shock_size
                else:  # gets ruined bailout process occurs
                    #print(f"agent {agent} is ruined and getting bailed out")
                    savings_shock = 0 - (agent_reserves[agent] - shock_size)
                    #print(f" giving agent {agent} {savings_shock} with savings reserve of {savings_reserve}")
                    if savings_reserve - savings_shock > 0:
                        agent_reserves[agent] += savings_shock - shock_size
                        savings_reserve -= savings_shock
                    else:
                        agent_reserves[agent] += savings_shock - shock_size
                        savings_reserve -= savings_shock
                        #print(f"Savings circle ruined at {time_step} with reserve shortfall of {savings_reserve}")
                        return time_step
        time_step += 1
    #print(f"Savings circle doesn't get ruined has reserves of {savings_reserve}")
    return time_step




    
