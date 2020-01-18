from cython cimport view
import numpy as np
cimport numpy as np

DTYPE = np.float
ctypedef np.float_t DTYPE_t


# Simulations keeping aggregate attributes fixed
cdef int simulate_effect(double p, double avg_income, double avg_shock_time, double max_shock_size, int num_agents=2, int diff=0):
    cdef int i
    #Per Simulation Variables
    cdef np.ndarray incomes
    cdef np.ndarray shock_times_param
    cdef np.ndarray shock_size_param
    if diff == 0:
        incomes = np.full(num_agents, avg_income , dtype=DTYPE)
        shock_times_param = np.full(num_agents, avg_shock_time, dtype=DTYPE)
        shock_size_param = np.full(num_agents, max_shock_size, dtype=DTYPE)
    elif diff == 1:
        #creating incomes with fixed average income
        incomes = np.array([0.75, 0.25]) * num_agents * avg_income
        shock_times_param = np.full(num_agents, avg_shock_time, dtype=DTYPE)
        shock_size_param = np.full(num_agents, max_shock_size, dtype=DTYPE)
    elif diff == 2:
        incomes = np.full(num_agents, avg_income, dtype=DTYPE)
        #creating shock_times with fixed average shock times
        shock_times_param = np.array([0.75, 0.25]) * num_agents * avg_shock_time
        shock_size_param = np.full(num_agents, max_shock_size, dtype=DTYPE)
    elif diff == 3:
        incomes = np.full(num_agents, avg_income , dtype=DTYPE)
        shock_times_param = np.full(num_agents, avg_shock_time, dtype=DTYPE)
        #creating shock_sizes with fixed average shock size
        shock_size_param = np.array([0.75, 0.25]) * num_agents * max_shock_size



    cdef bint savings_ruined = False
    cdef double savings_reserve = 0
    cdef np.ndarray agent_reserves = np.zeros(num_agents)
    cdef list agent_shock_times = [np.random.poisson(shock_times_param[i], 1000) for i in range(num_agents)]
    cdef int time_step = 0
    cdef int agent
    cdef double shock_size
    cdef double savings_shock
    while not savings_ruined:
        agent_reserves = agent_reserves + (1 - p)*incomes
        savings_reserve += sum(p*incomes)
        # Simulating for each agent
        for agent in range(num_agents):
            try:
                for i in range(agent_shock_times[agent][time_step]):  # number of shocks in a given time interval
                    if savings_ruined:
                        break
                    shock_size = np.random.uniform(0, shock_size_param[agent])  # getting shock sizes per shock. Shock size at most twice income
                    if agent_reserves[agent] - shock_size > 0:
                        agent_reserves[agent] -= shock_size
                    else:  # gets ruined bailout process occurs
                        savings_shock = 0 - (agent_reserves[agent] - shock_size)
                        if savings_reserve - savings_shock > 0:
                            agent_reserves[agent] += savings_shock - shock_size
                            savings_reserve -= savings_shock
                        else:
                            agent_reserves[agent] += savings_shock - shock_size
                            savings_reserve -= savings_shock
                            print(f"Savings circle ruined at {time_step} with reserve shortfall of {savings_reserve}")
                            savings_ruined = True
                            return time_step
            except IndexError:
                print(f"Savings circle doesn't get ruined has reserves of {savings_reserve}")
                return time_step
        time_step += 1
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
    cdef int i
    for i in range(num_trials):
        simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=1)
        simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=0)
    cdef list r1
    cdef list r2
    cdef list r3
    cdef list r4
    r1 = savings_ruin_time_diff[:]
    r2 = savings_ruin_time[:]

    savings_ruin_time_diff.clear()

    cdef list income_effects = [r1[:], r2[:] , r3[:] , r4[:]]
    for i in range(num_trials):
       simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=2)
    r1 = savings_ruin_time_diff[:]

    savings_ruin_time_diff.clear()

    cdef list dist_time_effects = [r1[:], r2[:], r3[:], r4[:]]

    for i in range(num_trials):
        simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=3)
    r1 = savings_ruin_time_diff[:]

    savings_ruin_time_diff.clear()
    cdef list dist_size_effects = [r1[:], r2[:], r3[:], r4[:]]

    return income_effects , dist_time_effects, dist_size_effects


    
