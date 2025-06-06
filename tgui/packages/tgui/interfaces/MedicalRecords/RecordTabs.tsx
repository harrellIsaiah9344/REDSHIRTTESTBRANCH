import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { useBackend, useLocalState } from 'tgui/backend';
import {
  Stack,
  Input,
  Section,
  Tabs,
  NoticeBox,
  Box,
  Icon,
  Button,
} from 'tgui/components';
import { JOB2ICON } from '../common/JobToIcon';
import { isRecordMatch } from '../SecurityRecords/helpers';
import { MedicalRecord, MedicalRecordData } from './types';

/** Displays all found records. */
export const MedicalRecordTabs = (props) => {
  const { act, data } = useBackend<MedicalRecordData>();
  const { records = [], station_z } = data;

  const errorMessage = !records.length
    ? 'No records found.'
    : 'No match. Refine your search.';

  const [search, setSearch] = useLocalState('search', '');

  const sorted: MedicalRecord[] = flow([
    filter((record: MedicalRecord) => isRecordMatch(record, search)),
    sortBy((record: MedicalRecord) => record.name?.toLowerCase()),
  ])(records);

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Input
          fluid
          onInput={(_, value) => setSearch(value)}
          placeholder="Name/Job/DNA"
        />
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <Tabs vertical>
            {!sorted.length ? (
              <NoticeBox>{errorMessage}</NoticeBox>
            ) : (
              sorted.map((record, index) => (
                <CrewTab key={index} record={record} />
              ))
            )}
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Item align="center">
        <Stack fill>
          <Stack.Item>
            <Button
              disabled
              icon="plus"
              tooltip="Add new records by inserting a 1 by 1 meter photo into the terminal. You do not need this screen open."
            >
              Create
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

/** Individual crew tab */
const CrewTab = (props: { record: MedicalRecord }) => {
  const [selectedRecord, setSelectedRecord] = useLocalState<
    MedicalRecord | undefined
  >('medicalRecord', undefined);

  const { act, data } = useBackend<MedicalRecordData>();
  const { assigned_view } = data;
  const { record } = props;
  const { crew_ref, name, rank } = record;

  /** Sets the record to preview */
  const selectRecord = (record: MedicalRecord) => {
    if (selectedRecord?.crew_ref === crew_ref) {
      setSelectedRecord(undefined);
    } else {
      // GOD, I REALLY HATE IT!
      // THIS FUCKING HACK NEEDED CAUSE "WINSET MAP"
      // MAKING UI DISAPPEAR, AND WE NEED RE-RENDER SHIT
      // AFTER BYOND DONE MAKING THEIR SHIT
      // Anyway... that's better than hack before
      if (selectedRecord === undefined) {
        setTimeout(() => {
          act('view_record', {
            assigned_view: assigned_view,
            crew_ref: crew_ref,
          });
        });
      }
      setSelectedRecord(record);
      act('view_record', { assigned_view: assigned_view, crew_ref: crew_ref });
    }
  };

  return (
    <Tabs.Tab
      className="candystripe"
      label={name}
      onClick={() => selectRecord(record)}
      selected={selectedRecord?.crew_ref === crew_ref}
    >
      <Box wrap>
        <Icon name={JOB2ICON[rank] || 'question'} /> {name}
      </Box>
    </Tabs.Tab>
  );
};
