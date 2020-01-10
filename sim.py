import numpy as np


DEBUG = False  ## Set this to true if you want to see what's happening at each step



#Global Simulation Fixed Variables
savings_ruin_time_diff = []
savings_ruin_time = []
savings_shortfall_diff = []
savings_shortfall = []

# Simulations keeping aggregate atteributes fixed
def simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, diff=False, income=True):
    savings_shock_times = []
    savings_shock_sizes = []
    #Per Simulation Variables
    if not diff:
        incomes = np.full(num_agents, avg_income)
        shock_times_param = np.full(num_agents, avg_shock_time)
    else:
        if income:
            #creating incomes with fixed average income
            incomes = np.random.randint(100, size=num_agents) + 1
            incomes = incomes / sum(incomes)
            incomes = incomes * (num_agents * avg_income)
            shock_times_param = np.full(num_agents, avg_shock_time)
        else:
            #creating shock_times with fixed average shock times
            shock_times_param = np.random.randint(100, size=num_agents) + 1
            shock_times_param = shock_times_param / sum(shock_times_param)
            shock_times_param = shock_times_param * (num_agents * avg_shock_time)
            incomes = np.full(num_agents, avg_income)

    savings_ruined = False
    savings_reserve = 0
    agent_ruin_times = [[] for i in range(num_agents)]
    agent_reserves = np.zeros(num_agents)
    agent_shock_times = [np.random.poisson(shock_times_param[i], 1000000) for i in range(num_agents)]
    time_step = 0
    while not savings_ruined:
        agent_reserves = agent_reserves + (1 - p)*incomes
        savings_reserve += sum(p*incomes)
        # Simulating for each agent
        for agent in range(num_agents):
            if DEBUG: print(f"{agent_shock_times[agent][time_step]} shocks happening in this time period for agent {agent} ")
            for i in range(agent_shock_times[agent][time_step]):  # number of shocks in a given time interval
                if savings_ruined:
                    break
                shock_size = np.random.uniform(0, max_shock_size)  # getting shock sizes per shock. Shock size at most twice income
                if DEBUG: print(f" shock {i} of size {shock_size} happenings with reserve {agent_reserves[agent]}")
                if agent_reserves[agent] - shock_size > 0:
                    agent_reserves[agent] -= shock_size
                else:  # gets ruined bailout process occurs
                    if DEBUG: print(f"agent {agent} is ruined and getting bailed out")
                    agent_ruin_times[agent].append(time_step)
                    savings_shock = 0 - (agent_reserves[agent] - shock_size)
                    if DEBUG: print(f" giving agent {agent} {savings_shock} with savings reserve of {savings_reserve}")
                    if savings_reserve - savings_shock > 0:
                        agent_reserves[agent] += savings_shock - shock_size
                        savings_reserve -= savings_shock
                    else:
                        agent_reserves[agent] += savings_shock - shock_size
                        savings_reserve -= savings_shock
                        if DEBUG: print(f" savings circle is ruined at time {time_step}")
                        if diff:
                            savings_ruin_time_diff.append(time_step)
                            savings_shortfall_diff.append(savings_reserve)
                        else:
                            savings_ruin_time.append(time_step)
                            savings_shortfall.append(savings_reserve)
                        savings_ruined = True
                        break


        if DEBUG: print(f" Time Step {time_step} executed ")
        time_step += 1
        if DEBUG:
            for agent in range(num_agents):
                print(f"Agent {agent} has income {incomes[agent]} reserves {agent_reserves[agent]} and has been ruined {len(agent_ruin_times[agent])} times")
            print(f"Savings reserve is {savings_reserve}")
    return savings_shock_times , savings_shock_sizes








def get_effects(num_trials, p, avg_income, avg_shock_time, max_shock_size, num_agents):
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
    for i in range(num_trials):
        results_diff = []
        results = []
        results_diff.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, True, income=True))
        results.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, False, income=True))
    r1 = savings_ruin_time_diff[:]
    r2 = savings_ruin_time[:]
    r3 = savings_shortfall_diff[:]
    r4 = savings_shortfall[:]
    savings_ruin_time_diff.clear()
    savings_ruin_time.clear()
    savings_shortfall_diff.clear()
    savings_shortfall.clear()
    income_effects = [r1[:], r2[:] , r3[:] , r4[:]]
    for i in range(num_trials):
        results_diff = []
        results = []
        results_diff.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, True, income=False))
        results.append(simulate_effect(p, avg_income, avg_shock_time, max_shock_size, num_agents, False, income=False))
    r1 = savings_ruin_time_diff[:]
    r2 = savings_ruin_time[:]
    r3 = savings_shortfall_diff[:]
    r4 = savings_shortfall[:]
    savings_ruin_time_diff.clear()
    savings_ruin_time.clear()
    savings_shortfall_diff.clear()
    savings_shortfall.clear()
    dist_effects = [r1[:], r2[:], r3[:], r4[:]]

    return income_effects , dist_effects


if __name__ == "__main__":
    inc , dist = get_effects(100, 0.2, 100, 2,100, 3)
    
