from cython.view cimport array
import os
import numpy as np
cimport numpy as np
from multiprocessing import Queue, Pool

DTYPE = np.float
ctypedef np.float_t DTYPE_t


# Simulations keeping aggregate attributes fixed
cdef float simulate_effect(double p, double avg_income, double avg_shock_time, double max_shock_size, int num_agents=2, int diff=0):
    cdef int i
    cdef int j
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








cpdef get_effects(int num_trials, double p, double avg_income, double avg_shock_time, double max_shock_size, int num_agents=2):
    """
    :param num_trials: number of simulations to run
    :param p: proportion of income that should be given to the savings circle
    :param avg_income:  average income per agent
    :param avg_shock_time: average number of shocks per time step
    :param max_shock_size: maximum shock size per time step (uniform distribution between 0 and max size)
    :param num_agents:  number of agents to run the simulation for
    :return: Two dimensional array the first index is for varied income and second index is for varying shocks:
            Each array has the ruin times for each run and the shortfall that would have been needed to avoid ruin.
    """
    cdef list no_effect = []
    cdef list income_effect = []
    cdef list time_effect = []
    cdef list size_effect = []
    cdef int i
    for i in range(num_trials):
        no_effect.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=0))
        income_effect.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=1))
        time_effect.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=2))
        size_effect.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=3))


    return no_effect , income_effect , time_effect , size_effect

# def get_effects_pooled(int num_trials, double p, double avg_income, double avg_shock_time, double max_shock_size, int num_agents=2):
#     """
#     :param num_trials: number of simulations to run
#     :param p: proportion of income that should be given to the savings circle
#     :param avg_income:  average income per agent
#     :param avg_shock_time: average number of shocks per time step
#     :param max_shock_size: maximum shock size per time step (uniform distribution between 0 and max size)
#     :param num_agents:  number of agents to run the simulation for
#     :return: Two dimensional array the first index is for varied income and second index is for varying shocks:
#             Each array has the ruin times for each run and the shortfall that would have been needed to avoid ruin.
#     """
#     no_effect = Queue()
#     income_effect = Queue()
#     time_effect = Queue()
#     size_effect = Queue()
#     with Pool(processes=os.cpu_count()) as pool:
#         pool.map(lambda x:no_effect.put(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=0)), range(num_trials))
#         pool.map(lambda x:income_effect.put(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=1)), range(num_trials))
#         pool.map(lambda x:time_effect.put(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=2)), range(num_trials))
#         pool.map(lambda x:size_effect.put(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=3)), range(num_trials))
#
#     return no_effect , income_effect , time_effect , size_effect


    
